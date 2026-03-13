#!/bin/bash
set -euo pipefail

# Claude Codeのネストセッション検知を回避
unset CLAUDECODE
# GITHUB_TOKENをunsetしClaude CLIにローカル認証のみ使わせる
unset GITHUB_TOKEN
unset GH_TOKEN

# 環境変数チェック
: "${ISSUE_NUMBER:?ISSUE_NUMBER is required}"
: "${ISSUE_TITLE:?ISSUE_TITLE is required}"

BRANCH="auto-impl/issue-${ISSUE_NUMBER}"
REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q '.nameWithOwner')}"

# ブランチ作成
git checkout -b "${BRANCH}"

# Claude Code CLI に実装・コミット・プッシュ・PR作成まで全て任せる
claude -p \
  --dangerously-skip-permissions \
  "Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

${ISSUE_BODY:-}

上記Issueの内容を実装してください。

## 作業手順
1. Issueの内容に従って実装する
2. 実装が完了したらコミットする（コミットメッセージは日本語）
3. git push origin ${BRANCH} でプッシュする
4. gh pr create でPRを作成する（タイトル・本文は日本語、本文に Closes #${ISSUE_NUMBER} を含める）
5. Issue #${ISSUE_NUMBER} にPR作成完了のコメントを投稿する（gh issue comment）"
