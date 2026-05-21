import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = req.headers.get("Authorization");

  if (!supabaseUrl || !anonKey || !serviceRoleKey || !authorization) {
    return json(
      { error: "Server is not configured for account deletion" },
      500,
    );
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();

  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey);
  const userId = user.id;

  const attempts = await admin
    .from("ai_quiz_attempts")
    .select("id")
    .eq("user_id", userId);
  if (attempts.error) {
    return json(
      { error: `Failed to load quiz attempts: ${attempts.error.message}` },
      500,
    );
  }
  const attemptIds = attempts.data.map((attempt) => attempt.id);
  if (attemptIds.length > 0) {
    const { error } = await admin
      .from("ai_quiz_answers")
      .delete()
      .in("attempt_id", attemptIds);
    if (error) {
      return json(
        { error: `Failed to delete quiz answers: ${error.message}` },
        500,
      );
    }
  }

  const quizzes = await admin
    .from("ai_quizzes")
    .select("id")
    .eq("user_id", userId);
  if (quizzes.error) {
    return json(
      { error: `Failed to load quizzes: ${quizzes.error.message}` },
      500,
    );
  }
  const quizIds = quizzes.data.map((quiz) => quiz.id);
  if (quizIds.length > 0) {
    const { error } = await admin
      .from("ai_quiz_questions")
      .delete()
      .in("quiz_id", quizIds);
    if (error) {
      return json(
        { error: `Failed to delete quiz questions: ${error.message}` },
        500,
      );
    }
  }

  const sessions = await admin
    .from("flashcard_sessions")
    .select("id")
    .eq("user_id", userId);
  if (sessions.error) {
    return json(
      { error: `Failed to load flashcard sessions: ${sessions.error.message}` },
      500,
    );
  }
  const sessionIds = sessions.data.map((session) => session.id);
  if (sessionIds.length > 0) {
    const { error } = await admin
      .from("flashcard_results")
      .delete()
      .in("session_id", sessionIds);
    if (error) {
      return json(
        { error: `Failed to delete flashcard results: ${error.message}` },
        500,
      );
    }
  }

  const tables = [
    "ai_quiz_attempts",
    "ai_quizzes",
    "flashcard_sessions",
    "favorites",
    "kanji_examples",
    "word_examples",
    "study_records",
    "study_sessions",
    "user_progress",
  ];

  for (const table of tables) {
    const { error } = await admin.from(table).delete().eq("user_id", userId);
    if (error) {
      return json({ error: `Failed to delete ${table}: ${error.message}` }, 500);
    }
  }

  const { error: profileError } = await admin
    .from("users")
    .delete()
    .eq("id", userId);
  if (profileError) {
    return json({ error: `Failed to delete profile: ${profileError.message}` }, 500);
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
  if (deleteError) {
    return json({ error: `Failed to delete auth user: ${deleteError.message}` }, 500);
  }

  return json({ deleted: true });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
