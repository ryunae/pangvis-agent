# n8n Production Dockerfile for Railway
# 확장성과 안정성을 고려한 설정

FROM n8nio/n8n:latest

# 타임존 설정 (한국)
ENV TZ=Asia/Seoul
ENV GENERIC_TIMEZONE=Asia/Seoul

# n8n 기본 설정
ENV N8N_HOST=0.0.0.0
ENV N8N_PROTOCOL=https
ENV N8N_PORT=5678

# 보안 설정
ENV N8N_SECURE_COOKIE=true

# 실행 모드
ENV EXECUTIONS_MODE=queue
ENV QUEUE_BULL_REDIS_HOST=localhost

# 로그 설정
ENV N8N_LOG_LEVEL=info
ENV N8N_LOG_OUTPUT=console

# 헬스체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5678/healthz || exit 1

# 포트 노출
EXPOSE 5678

# 기본 실행
CMD ["n8n", "start"]
