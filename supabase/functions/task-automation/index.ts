import { createClient } from "npm:@supabase/supabase-js@2";

type RunType = "manual" | "cron" | "trigger" | "test";

type AutomationPayload = {
  run_type?: RunType;
  source?: string;
  notes?: string;
};

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-automation-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const validRunTypes = new Set<RunType>(["manual", "cron", "trigger", "test"]);

Deno.serve(handleRequest);

async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ ok: false, error: "Use POST para ejecutar el proceso." }, 405);
  }

  try {
    const payload = await readPayload(req);
    const runType = normalizeRunType(payload.run_type);
    const source = cleanText(payload.source) ?? "edge-function";
    const notes = cleanText(payload.notes);

    const supabase = createClient(getSupabaseUrl(), getSupabaseSecretKey(), {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    await verifyCaller(req, supabase);

    const { data, error } = await supabase.rpc("register_task_automation_run", {
      p_run_type: runType,
      p_source: source,
      p_notes: notes,
    });

    if (error) {
      throw new HttpError(500, error.message);
    }

    return json({
      ok: true,
      message: "Proceso automatico ejecutado.",
      run: data,
    });
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    const message = error instanceof Error ? error.message : "Error inesperado.";

    return json({ ok: false, error: message }, status);
  }
}

async function readPayload(req: Request): Promise<AutomationPayload> {
  const contentType = req.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return {};

  const body = await req.text();
  if (body.trim().isEmpty) return {};

  try {
    return JSON.parse(body) as AutomationPayload;
  } catch (_) {
    throw new HttpError(400, "JSON invalido en el body.");
  }
}

async function verifyCaller(
  req: Request,
  supabase: ReturnType<typeof createClient>,
): Promise<void> {
  const receivedSecret = req.headers.get("x-automation-secret");
  if (receivedSecret) {
    verifyAutomationSecret(receivedSecret);
    return;
  }

  const authorization = req.headers.get("authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    throw new HttpError(401, "Falta Authorization o x-automation-secret.");
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new HttpError(401, "Sesion invalida para ejecutar la Function.");
  }
}

function verifyAutomationSecret(receivedSecret: string): void {
  const expectedSecret = Deno.env.get("AUTOMATION_SECRET");
  if (!expectedSecret) {
    throw new HttpError(500, "Falta configurar AUTOMATION_SECRET.");
  }

  if (receivedSecret !== expectedSecret) {
    throw new HttpError(401, "Secreto de automatizacion invalido.");
  }
}

function normalizeRunType(value: AutomationPayload["run_type"]): RunType {
  if (value && validRunTypes.has(value)) return value;
  return "manual";
}

function cleanText(value: string | undefined): string | null {
  const cleanValue = value?.trim();
  return cleanValue ? cleanValue.slice(0, 500) : null;
}

function getSupabaseUrl(): string {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) throw new HttpError(500, "Falta configurar SUPABASE_URL.");
  return url;
}

function getSupabaseSecretKey(): string {
  const secretKeys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (secretKeys) {
    try {
      const parsed = JSON.parse(secretKeys) as Record<string, string>;
      const key = parsed.default ?? Object.values(parsed).find(Boolean);
      if (key) return key;
    } catch (_) {
      throw new HttpError(500, "SUPABASE_SECRET_KEYS no tiene JSON valido.");
    }
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (serviceRoleKey) return serviceRoleKey;

  throw new HttpError(
    500,
    "Falta SUPABASE_SECRET_KEYS o SUPABASE_SERVICE_ROLE_KEY para usar el cliente admin.",
  );
}

function json(body: unknown, status = 200): Response {
  return Response.json(body, {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
