# Base de leads no Supabase

## 1) Criar a estrutura no banco
1. Abra seu projeto em `https://supabase.com`.
2. Va em `SQL Editor`.
3. Cole o conteudo de `database/supabase_leads.sql`.
4. Execute o script.

Isso cria:
- Tabela `public.leads` (cadastro principal de clientes).
- Tabela `public.lead_interactions` (historico comercial).
- View `public.vw_leads_funil` (resumo por etapa).
- Regras RLS para permitir `insert` anonimo no formulario com consentimento LGPD.

## 2) Configurar a landing page
As credenciais ficam em `.env` e o HTML carrega `lead-capture-config.js`.

1. Preencha `.env` na raiz:

```env
SUPABASE_URL=https://SEU-PROJETO.supabase.co
SUPABASE_ANON_KEY=SUA_ANON_KEY
```

2. Gere o arquivo de configuracao:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\generate-lead-capture-config.ps1
```

3. O arquivo `lead-capture-config.js` sera criado automaticamente e lido por `index.html` e `pagina-vendas-inema.html`.

Onde pegar os valores:
- `supabaseUrl`: `Project Settings > API > Project URL`
- `supabaseAnonKey`: `Project Settings > API > anon public`

## 3) Teste rapido
1. Abra a pagina e envie o formulario de captacao.
2. No Supabase, confira `Table Editor > leads`.
3. Se quiser validar por SQL:

```sql
select full_name, email, whatsapp, interest, source, created_at
from public.leads
order by created_at desc
limit 20;
```

## 4) Operacao comercial
- Atualize `status` do lead (`novo`, `qualificando`, `contatado`, `proposta`, `convertido`, `perdido`).
- Registre contatos na `lead_interactions`.
- Acompanhe o funil por `vw_leads_funil`.
