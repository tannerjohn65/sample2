#!/bin/bash
set -euo pipefail

# 環境変数チェック
: "${ISSUE_NUMBER:?ISSUE_NUMBER is required}"
: "${ISSUE_TITLE:?ISSUE_TITLE is required}"

BRANCH="auto-impl/issue-${ISSUE_NUMBER}"
REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q '.nameWithOwner')}"

# ブランチ作成
git checkout -b "${BRANCH}"

# Claude Code CLI 実行
claude -p \
  --dangerously-skip-permissions \
  "Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}

${ISSUE_BODY:-}

上記Issueの内容を実装してください。
- コミットメッセージ・PR本文は日本語で書くこと
- 実装が完了したらコミットしてください"

# 機密ファイルチェック
SENSITIVE=$(git diff --name-only main...HEAD | grep -E '\.(env|key|pem)$|secrets/' || true)
if [ -n "${SENSITIVE}" ]; then
  gh issue comment "${ISSUE_NUMBER}" --repo "${REPO}" \
    --body "## 機密ファイルの変更を検知しました

以下のファイルが変更に含まれているため、自動PRを中止しました:
\`\`\`
${SENSITIVE}
\`\`\`
手動で確認してください。"
  exit 1
fi

# 変更がない場合
if git diff --quiet main...HEAD; then
  gh issue comment "${ISSUE_NUMBER}" --repo "${REPO}" \
    --body "## 自動実装の結果

コードの変更はありませんでした。Issueの内容をより具体的に記述してください。"
  exit 0
fi

# Push & PR作成
git push origin "${BRANCH}"

PR_URL=$(gh pr create \
  --repo "${REPO}" \
  --base main \
  --head "${BRANCH}" \
  --title "Issue #${ISSUE_NUMBER}: ${ISSUE_TITLE}" \
  --body "$(cat <<EOF
## 概要

Issue #${ISSUE_NUMBER} の自動実装です。

Closes #${ISSUE_NUMBER}

## 変更内容

$(git log main..HEAD --pretty=format:'- %s')
EOF
)")

# Issueにコメント
gh issue comment "${ISSUE_NUMBER}" --repo "${REPO}" \
  --body "## 自動実装が完了しました

PRを作成しました: ${PR_URL}

レビューをお願いします。"
