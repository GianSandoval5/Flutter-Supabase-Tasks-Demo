import { createClient } from "npm:@supabase/supabase-js@2";

type SuggestionType = "task" | "event";

type SuggestionsPayload = {
  limit?: number;
  user_id?: string;
};

type TaskRow = {
  id: number;
  title: string;
  is_done: boolean;
  created_at: string;
  user_id: string;
};

type TaskSuggestion = {
  title: string;
  type: SuggestionType;
  reason: string;
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

Deno.serve(handleRequest);

async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ ok: false, error: "Use POST para pedir sugerencias." }, 405);
  }

  try {
    const payload = await readPayload(req);
    const supabase = createClient(getSupabaseUrl(), getSupabaseSecretKey(), {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const userId = await resolveUserId(req, supabase, payload.user_id);
    const tasks = userId ? await fetchUserTasks(supabase, userId) : [];
    const suggestions = buildSuggestions(tasks, normalizeLimit(payload.limit));

    return json({
      ok: true,
      user_id: userId,
      suggestions,
    });
  } catch (error) {
    const status = error instanceof HttpError ? error.status : 500;
    const message = error instanceof Error ? error.message : "Error inesperado.";

    return json({ ok: false, error: message }, status);
  }
}

async function readPayload(req: Request): Promise<SuggestionsPayload> {
  const contentType = req.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return {};

  const body = await req.text();
  if (body.trim().isEmpty) return {};

  try {
    return JSON.parse(body) as SuggestionsPayload;
  } catch (_) {
    throw new HttpError(400, "JSON invalido en el body.");
  }
}

async function resolveUserId(
  req: Request,
  supabase: ReturnType<typeof createClient>,
  requestedUserId?: string,
): Promise<string | null> {
  const receivedSecret = req.headers.get("x-automation-secret");
  if (receivedSecret) {
    verifyAutomationSecret(receivedSecret);
    return cleanText(requestedUserId);
  }

  const authorization = req.headers.get("authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    throw new HttpError(401, "Falta Authorization o x-automation-secret.");
  }

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new HttpError(401, "Sesion invalida para pedir sugerencias.");
  }

  return data.user.id;
}

async function fetchUserTasks(
  supabase: ReturnType<typeof createClient>,
  userId: string,
): Promise<TaskRow[]> {
  const { data, error } = await supabase
    .from("tasks")
    .select("id,title,is_done,created_at,user_id")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(50);

  if (error) {
    throw new HttpError(500, error.message);
  }

  return (data ?? []) as TaskRow[];
}

function buildSuggestions(tasks: TaskRow[], limit: number): TaskSuggestion[] {
  const suggestions: TaskSuggestion[] = [];
  const pending = tasks.filter((task) => !task.is_done);
  const completed = tasks.filter((task) => task.is_done);
  const oldestPending = [...pending].sort(
    (a, b) =>
      new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
  )[0];
  const recentTasks = tasks.filter((task) => ageInDays(task.created_at) <= 7);
  const day = new Date().getUTCDay();

  if (tasks.length === 0) {
    suggestions.push(
      {
        title: "Crear tu primera lista de pendientes",
        type: "task",
        reason: "Aun no hay tareas registradas para este usuario.",
      },
      {
        title: "Planificar prioridades de hoy",
        type: "event",
        reason: "Es un buen punto de partida para organizar el dia.",
      },
      {
        title: "Definir una tarea corta de 15 minutos",
        type: "task",
        reason: "Una tarea pequena ayuda a mostrar el flujo completo de la demo.",
      },
    );
  }

  if (pending.length >= 3) {
    suggestions.push({
      title: "Revisar tareas pendientes de hoy",
      type: "task",
      reason: `Tienes ${pending.length} tareas sin completar.`,
    });
  }

  if (oldestPending && ageInDays(oldestPending.created_at) >= 2) {
    suggestions.push({
      title: `Cerrar pendiente antiguo: ${truncateTitle(oldestPending.title)}`,
      type: "task",
      reason: "Hay una tarea pendiente con varios dias de antiguedad.",
    });
  }

  if (completed.length > 0) {
    suggestions.push({
      title: "Crear seguimiento de tareas completadas",
      type: "task",
      reason: `Ya completaste ${completed.length} tarea(s); puedes generar un seguimiento.`,
    });
  }

  if (recentTasks.length >= 4) {
    suggestions.push({
      title: "Agrupar tareas recientes por prioridad",
      type: "event",
      reason: "Hay varias tareas creadas durante los ultimos 7 dias.",
    });
  }

  if (day === 1) {
    suggestions.push({
      title: "Planificar objetivos de la semana",
      type: "event",
      reason: "Es lunes; conviene organizar el trabajo semanal.",
    });
  }

  if (day === 5) {
    suggestions.push({
      title: "Revisar avance semanal",
      type: "event",
      reason: "Es viernes; puedes cerrar la semana con una revision.",
    });
  }

  if (suggestions.length === 0) {
    suggestions.push(
      {
        title: "Revisar el estado general de tareas",
        type: "task",
        reason: "Tus tareas estan equilibradas; una revision rapida mantiene el control.",
      },
      {
        title: "Planificar el siguiente bloque de enfoque",
        type: "event",
        reason: "Puedes reservar tiempo para avanzar en una tarea importante.",
      },
    );
  }

  return dedupeSuggestions(suggestions).slice(0, limit);
}

function dedupeSuggestions(suggestions: TaskSuggestion[]): TaskSuggestion[] {
  const seen = new Set<string>();
  return suggestions.filter((suggestion) => {
    const key = suggestion.title.toLowerCase();
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function normalizeLimit(value: number | undefined): number {
  if (!value || Number.isNaN(value)) return 4;
  return Math.min(Math.max(Math.trunc(value), 1), 6);
}

function ageInDays(date: string): number {
  const timestamp = new Date(date).getTime();
  if (Number.isNaN(timestamp)) return 0;
  return Math.floor((Date.now() - timestamp) / 86_400_000);
}

function truncateTitle(title: string): string {
  const cleanTitle = title.trim();
  if (cleanTitle.length <= 42) return cleanTitle;
  return `${cleanTitle.slice(0, 39)}...`;
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

function cleanText(value: string | undefined): string | null {
  const cleanValue = value?.trim();
  return cleanValue || null;
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
