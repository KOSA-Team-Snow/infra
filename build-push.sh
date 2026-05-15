#!/bin/bash
set -e

# ── 경로 설정 (스크립트 위치 기준) ────────────────────
# infra 레포와 Flaskapp 레포가 같은 부모 폴더에 있다고 가정합니다.
# 다른 경로에 클론한 경우: FLASKAPP_DIR=/path/to/Flaskapp ./build-push.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLASKAPP_DIR="${FLASKAPP_DIR:-${SCRIPT_DIR}/../Flaskapp}"
VALUES_FILE="${SCRIPT_DIR}/helm/flaskapp/values.yaml"

# ── 설정 ──────────────────────────────────────────────
AWS_REGION="ap-northeast-2"
ECR_URL="080252689380.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE_NAME="flaskapp"

# 이미지 태그: git commit SHA (앞 7자리)
GIT_SHA=$(git -C "$FLASKAPP_DIR" rev-parse --short HEAD)
IMAGE_TAG="${GIT_SHA}"
FULL_IMAGE="${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "▶ 빌드 시작"
echo "  이미지: ${FULL_IMAGE}"
echo ""

# ── ECR 로그인 ─────────────────────────────────────────
echo "▶ ECR 로그인"
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_URL"

# ── Docker 빌드 (linux/amd64 고정: K8s 노드가 x86_64) ─
echo "▶ Docker 빌드"
docker build --platform linux/amd64 -t "${IMAGE_NAME}:${IMAGE_TAG}" "$FLASKAPP_DIR"

# ── ECR 태깅 + Push ────────────────────────────────────
echo "▶ ECR Push"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$FULL_IMAGE"
docker push "$FULL_IMAGE"

# latest 태그도 함께 push
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_URL}/${IMAGE_NAME}:latest"
docker push "${ECR_URL}/${IMAGE_NAME}:latest"

# ── values.yaml image.tag 자동 업데이트 ───────────────
echo "▶ values.yaml image.tag 업데이트: ${IMAGE_TAG}"
sed -i.bak "s/^  tag: .*/  tag: \"${IMAGE_TAG}\"/" "$VALUES_FILE" && rm "${VALUES_FILE}.bak"

echo ""
echo "완료: ${FULL_IMAGE}"
echo ""
echo "다음 단계: values.yaml이 자동 업데이트됨 → 아래 명령어로 Git에 반영"
echo "  git add helm/flaskapp/values.yaml"
echo "  git commit -m \"chore(helm): image.tag ${IMAGE_TAG}로 업데이트\""
echo "  git push"
