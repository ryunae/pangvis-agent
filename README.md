# n8n Railway 자동 배포 가이드

> **도메인**: n8n.ryunae.com
> **목적**: 노션/구글 API 업무자동화 + OpenClaw 테스트

---

## 📁 프로젝트 구조

```
n8n-railway-setup/
├── Dockerfile              # n8n 컨테이너 설정
├── railway.toml            # Railway 배포 설정
├── .env.example            # 환경변수 템플릿
├── n8n-workflows/
│   ├── weekly-backup-gdrive.json    # 주간 백업 (일요일 3AM)
│   └── monthly-update-check.json    # 월간 업데이트 체크 (매월 1일)
└── README.md
```

---

## 🚀 배포 단계

### Step 1: GitHub 레포지토리 준비

1. 이 폴더의 파일들을 `https://github.com/ryunae/pangvis-agent`에 푸시
2. 또는 새 레포지토리 생성 후 푸시

```bash
git add .
git commit -m "Add n8n Railway deployment config"
git push origin main
```

### Step 2: Railway 프로젝트 설정

1. [Railway](https://railway.app) 대시보드 접속
2. **New Project** → **Deploy from GitHub repo** 선택
3. `pangvis-agent` 레포지토리 연결
4. 자동으로 Dockerfile 감지하여 빌드 시작

### Step 3: PostgreSQL 추가

1. 프로젝트 내에서 **+ New** → **Database** → **PostgreSQL**
2. 자동으로 DB 변수 생성됨 (`PGHOST`, `PGPORT` 등)

### Step 4: 환경변수 설정

Railway 프로젝트 → n8n 서비스 → **Variables** 탭에서 아래 변수 추가:

```env
# 필수
N8N_HOST=n8n.ryunae.com
N8N_PROTOCOL=https
WEBHOOK_URL=https://n8n.ryunae.com/

# 암호화 키 (터미널에서 생성: openssl rand -hex 32)
N8N_ENCRYPTION_KEY=생성한_키_입력

# 인증
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=강력한_비밀번호

# DB 연결 (Railway 변수 참조)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=${{Postgres.PGHOST}}
DB_POSTGRESDB_PORT=${{Postgres.PGPORT}}
DB_POSTGRESDB_DATABASE=${{Postgres.PGDATABASE}}
DB_POSTGRESDB_USER=${{Postgres.PGUSER}}
DB_POSTGRESDB_PASSWORD=${{Postgres.PGPASSWORD}}

# 타임존
GENERIC_TIMEZONE=Asia/Seoul
TZ=Asia/Seoul
```

### Step 5: 커스텀 도메인 연결 (Cloudflare)

#### Railway 설정:
1. n8n 서비스 → **Settings** → **Networking**
2. **Generate Domain** 또는 **Custom Domain** 추가
3. 도메인: `n8n.ryunae.com`

#### Cloudflare 설정:
1. DNS 레코드 추가:
   - **Type**: CNAME
   - **Name**: n8n
   - **Target**: Railway에서 제공하는 도메인
   - **Proxy**: OFF (DNS only) - SSL은 Railway에서 처리

2. SSL/TLS 설정:
   - **SSL/TLS** → **Full (strict)** 선택

---

## 🔐 Google API 설정 (OAuth)

### Google Cloud Console 설정

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 프로젝트 생성 또는 선택
3. **APIs & Services** → **OAuth consent screen** 설정
   - User Type: External
   - App name: n8n Automation
   - Authorized domains: `ryunae.com`

4. **Credentials** → **Create Credentials** → **OAuth client ID**
   - Application type: Web application
   - Name: n8n OAuth
   - **Authorized redirect URIs**:
     ```
     https://n8n.ryunae.com/rest/oauth2-credential/callback
     ```

5. Client ID와 Client Secret 복사

### n8n에서 Google 연결

1. n8n 접속 → **Credentials** → **Add Credential**
2. **Google OAuth2 API** 선택
3. Client ID, Client Secret 입력
4. **Connect** 클릭 → Google 로그인 → 권한 승인

---

## 🤖 AI API 연결

### 환경변수 추가 (Railway Variables)

```env
# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-api03-...

# OpenAI (ChatGPT)
OPENAI_API_KEY=sk-proj-...

# Google AI (Gemini)
GOOGLE_AI_API_KEY=AIza...

# Notion
NOTION_API_KEY=secret_...
```

### n8n 크레덴셜 설정

각 서비스별로 **Credentials** → **Add Credential**:

| 서비스 | Credential Type | 필요 값 |
|--------|-----------------|---------|
| Anthropic | Anthropic API | API Key |
| OpenAI | OpenAI API | API Key |
| Google AI | Google AI API | API Key |
| Notion | Notion API | Internal Integration Token |

---

## 📦 백업 설정

### 자동 백업 워크플로우 설치

1. n8n 접속 → **Workflows** → **Import**
2. `n8n-workflows/weekly-backup-gdrive.json` 업로드
3. Google Drive 크레덴셜 연결
4. Google Drive에 `n8n-backups` 폴더 생성
5. 워크플로우 **Active** 켜기

### 백업 스케줄
- **주기**: 매주 일요일 오전 3시 (KST)
- **내용**: 모든 워크플로우 + 크레덴셜 목록
- **저장 위치**: Google Drive `n8n-backups/`

---

## 🔄 업데이트 설정

### 자동 업데이트 체크 워크플로우

1. `n8n-workflows/monthly-update-check.json` import
2. 워크플로우 **Active** 켜기

### 업데이트 스케줄
- **주기**: 매월 1일 오전 9시 (KST)
- **동작**: 최신 n8n 버전 확인 → 업데이트 필요시 알림

### 수동 업데이트 방법
1. Railway 대시보드 접속
2. n8n 서비스 선택
3. **Settings** → **Redeploy**
4. latest 이미지로 자동 업데이트

---

## 🧪 OpenClaw 테스트 설정

OpenClaw 모델을 n8n에서 테스트하려면:

1. OpenClaw API 엔드포인트와 키 확보
2. n8n에서 **HTTP Request** 노드 사용
3. 또는 커스텀 노드 개발

---

## ⚠️ 트러블슈팅

### Google OAuth 콜백 에러

**증상**: "redirect_uri_mismatch" 에러

**해결**:
1. Google Cloud Console → Credentials
2. OAuth 클라이언트 편집
3. Redirect URI 정확히 입력:
   ```
   https://n8n.ryunae.com/rest/oauth2-credential/callback
   ```
4. 변경 후 5분 대기

### Railway 배포 실패

**증상**: Build failed

**확인**:
1. Dockerfile 문법 확인
2. Railway 로그 확인 (Deployments → View Logs)
3. 환경변수 누락 확인

### DB 연결 에러

**증상**: "Connection refused" 또는 "Authentication failed"

**확인**:
1. PostgreSQL 서비스 상태 확인
2. 변수 참조 형식 확인: `${{Postgres.PGHOST}}`
3. 서비스 간 연결 확인

---

## 📊 비용 관리 (Hobby $5/월)

### 리소스 모니터링
- Railway 대시보드에서 **Usage** 확인
- CPU, Memory, Bandwidth 사용량 체크

### 최적화 팁
1. `EXECUTIONS_DATA_MAX_AGE=168` (7일 보관)
2. 불필요한 워크플로우 비활성화
3. 실행 기록 정기 정리

---

## 🔗 관련 링크

- [n8n 공식 문서](https://docs.n8n.io)
- [Railway 문서](https://docs.railway.app)
- [Google Cloud Console](https://console.cloud.google.com)
- [Cloudflare Dashboard](https://dash.cloudflare.com)

---

**마지막 업데이트**: 2026-02-04
