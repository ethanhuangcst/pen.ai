# Database Structure

## Overview
This document describes the database structure for the Pen AI application. The database contains tables for users, AI connections, prompts, chats, chat messages, and AI providers.

## Tables

### _prisma_migrations

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | varchar(36) | NO | PRI |  |  |
| checksum | varchar(64) | NO |  |  |  |
| finished_at | datetime(3) | YES |  |  |  |
| migration_name | varchar(255) | NO |  |  |  |
| logs | text | YES |  |  |  |
| rolled_back_at | datetime(3) | YES |  |  |  |
| started_at | datetime(3) | NO |  | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| applied_steps_count | int unsigned | NO |  | 0 |  |

### ai_connections

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI |  | auto_increment |
| user_id | int | NO | MUL |  |  |
| apiKey | varchar(255) | NO |  |  |  |
| apiProvider | varchar(50) | NO |  |  |  |
| createdAt | timestamp | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| updatedAt | timestamp | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

### ai_providers

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | varchar(50) | NO | PRI |  |  |
| name | varchar(100) | NO |  |  |  |
| base_urls | json | NO |  |  |  |
| default_model | varchar(100) | NO |  |  |  |
| requires_auth | tinyint(1) | NO |  | 1 |  |
| auth_header | varchar(100) | YES |  |  |  |
| created_at | timestamp | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| updated_at | timestamp | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

### chat_messages

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | varchar(255) | NO | PRI |  |  |
| chat_id | varchar(255) | NO | MUL |  |  |
| content | text | NO |  |  |  |
| role | enum('user','assistant') | NO |  |  |  |
| provider | varchar(50) | YES |  | gpt-5.2-all |  |
| timestamp | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| created_at | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |

### chats

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | varchar(255) | NO | PRI |  |  |
| user_id | int | NO | MUL |  |  |
| name | varchar(255) | NO |  |  |  |
| timestamp | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| created_at | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| updated_at | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

### content_history

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| uuid | varchar(36) | NO | PRI |  |  |
| user_id | varchar(36) | YES |  |  |  |
| enhance_datetime | datetime | NO |  |  |  |
| original_content | text | NO |  |  |  |
| enhanced_content | text | NO |  |  |  |
| prompt_text | text | NO |  |  |  |
| ai_provider | varchar(255) | NO |  |  |  |
| created_at | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| updated_at | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

### prompts

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | varchar(255) | NO | PRI |  |  |
| user_id | int | NO | MUL |  |  |
| prompt_name | varchar(255) | NO |  |  |  |
| prompt_text | text | NO |  |  |  |
| created_datetime | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| updated_datetime | datetime | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |
| system_flag | varchar(20) | NO |  | WINGMAN |  |
| is_default | tinyint(1) | NO |  | 0 |  |

### system_config

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI |  | auto_increment |
| default_prompt_name | varchar(255) | YES |  |  |  |
| default_prompt_text | text | YES |  |  |  |
| content_history_count_low | int | NO |  | 10 |  |
| content_history_count_medium | int | NO |  | 20 |  |
| content_history_count_high | int | NO |  | 40 |  |
| created_at | timestamp | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| updated_at | timestamp | YES |  | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

### users

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI |  | auto_increment |
| name | varchar(191) | NO |  |  |  |
| email | varchar(191) | NO | UNI |  |  |
| password | varchar(191) | NO |  |  |  |
| profileImage | longtext | YES |  |  |  |
| createdAt | datetime(3) | NO |  | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| system_flag | varchar(20) | NO |  | WINGMAN |  |
| pen_content_history | int | NO |  | 10 |  |

## Relationships

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│   users    │────▶│ ai_connections │────▶│ ai_providers │
└────────────┘     └────────────┘     └────────────┘
      │                   │
      │                   │
      ▼                   ▼
┌────────────┐     ┌────────────┐     ┌───────────────┐
│   chats    │────▶│chat_messages│     │content_history│
└────────────┘     └────────────┘     └───────────────┘
      │                                   ▲
      │                                   │
      ▼                                   │
┌────────────┐                           │
│  prompts   │───────────────────────────┘
└────────────┘
```

## Key Points

1. **User Management**: The `users` table stores all user information, including authentication details and profile data.

2. **AI Connections**: The `ai_connections` table stores API keys and provider information for each user's AI services.

3. **Chat System**: The `chats` and `chat_messages` tables handle the chat functionality, allowing users to have multiple conversations with AI providers.

4. **Prompt Management**: The `prompts` table stores user-created prompts that can be reused in conversations. The `is_default` column indicates whether a prompt is the default prompt for a user.

5. **AI Provider Configuration**: The `ai_providers` table stores configuration information for different AI service providers.

6. **Content History**: The `content_history` table stores records of enhanced content, including the original content, enhanced content, prompt used, and AI provider.

7. **System Configuration**: The `system_config` table stores global system settings, including default prompt information and content history count options (LOW, MEDIUM, HIGH) that can be centrally managed.

8. **Data Consistency**: Foreign key relationships ensure data integrity between related tables.

9. **Timestamps**: Most tables include `created_at` and `updated_at` timestamps for tracking when records were created or modified.

10. **System Flag**: The `system_flag` column in several tables indicates whether records were created by the Wingman app or the Pen app.

## Security Considerations

- Passwords are stored as plain text in the `password` column. In a production environment, these should be hashed using a secure hashing algorithm.
- API keys in the `ai_connections` table are stored as plain text. These should be encrypted or stored in a secure vault in a production environment.
- Email addresses are unique to prevent duplicate user accounts.
