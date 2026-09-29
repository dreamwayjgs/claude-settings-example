import type { HookAPI } from "@oh-my-pi/pi-coding-agent/extensibility/hooks";

// Machine-local: omp's OpenAI login is a personal account.
// Ask once per session before the first prompt to an OpenAI-family model.
// "No" cancels the prompt and asks again next time; headless runs are refused.
export default function (pi: HookAPI): void {
  let approved = false;
  const reset = () => {
    approved = false;
  };
  pi.on("session_start", reset);
  pi.on("session_switch", reset);

  pi.on("before_agent_start", async (_event, ctx) => {
    if (approved) return;
    const provider = ctx.model?.provider ?? "";
    if (!provider.startsWith("openai")) return;
    const label = `${provider}/${ctx.model?.id}`;

    if (!ctx.hasUI) {
      process.stderr.write(`[openai-personal-warning] 개인 OpenAI 계정(${label}) — 화면 없는 실행에서는 확인할 수 없어 취소합니다.\n`);
      ctx.abort();
      return;
    }

    approved = await ctx.ui.confirm(
      "개인 OpenAI 계정",
      `${label}은 개인 계정입니다. 개인 작업이 맞나요? (회사 작업이면 아니오 후 anthropic으로 바꾸세요)`,
    );
    if (!approved) {
      ctx.ui.notify("요청을 취소했습니다.", "warning");
      ctx.abort();
    }
  });
}
