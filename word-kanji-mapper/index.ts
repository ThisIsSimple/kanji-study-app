import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// 테스트: kanji 테이블에서 첫 5개 조회
async function main() {
  console.log("Supabase 연결 테스트...\n");

  const { data, error } = await supabase
    .from("kanji")
    .select("id, character, jlpt, grade")
    .limit(5);

  if (error) {
    console.error("에러:", error.message);
    return;
  }

  console.log("조회 결과:");
  console.table(data);
}

main();
