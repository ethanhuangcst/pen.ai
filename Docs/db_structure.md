# Database Structure

## Overview
This document describes the database structure for the Pen AI application. The database contains tables for users, AI connections, prompts, chats, chat messages, and AI providers.

## Tables

### users

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI | NULL | auto_increment |
| name | varchar(191) | NO | | NULL | |
| email | varchar(191) | NO | UNI | NULL | |
| password | varchar(191) | NO | | NULL | |
| profileImage | varchar(191) | YES | | NULL | |
| createdAt | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| system_flag | varchar(20) | NO | | WINGMAN | |

**Sample Data:**
| id | name | email | system_flag |
|----|------|-------|-------------|
| 4 | Ethan Huang | me@ethanhuang.com | WINGMAN |
| 5 | Aidan Huang | aidan@ethanhuang.com | WINGMAN |
| 6 | Caroline | caroline.ye@me.com | WINGMAN |
| 456 | Test User | test@example.com | WINGMAN |
| 458 | User1 | user1@ethanhuang.com | WINGMAN |

### ai_connections

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI | NULL | auto_increment |
| user_id | int | NO | | NULL | |
| apiKey | varchar(191) | NO | | NULL | |
| apiProvider | varchar(191) | NO | | NULL | |
| createdAt | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| updatedAt | datetime(3) | YES | | NULL | |

**Relationships:**
- `user_id` references `users.id`

### prompts

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI | NULL | auto_increment |
| user_id | int | NO | | NULL | |
| prompt_name | varchar(191) | NO | | NULL | |
| prompt_text | text | NO | | NULL | |
| created_datetime | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| updated_datetime | datetime(3) | YES | | NULL | |
| system_flag | varchar(20) | NO | | WINGMAN | |

**Relationships:**
- `user_id` references `users.id`

### chats

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI | NULL | auto_increment |
| user_id | int | NO | | NULL | |
| name | varchar(191) | NO | | NULL | |
| timestamp | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| created_at | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| updated_at | datetime(3) | YES | | NULL | |

**Relationships:**
- `user_id` references `users.id`

### chat_messages

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI | NULL | auto_increment |
| chat_id | int | NO | | NULL | |
| content | text | NO | | NULL | |
| role | varchar(50) | NO | | NULL | |
| provider | varchar(100) | NO | | NULL | |
| timestamp | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| created_at | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |

**Relationships:**
- `chat_id` references `chats.id`

### ai_providers

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | int | NO | PRI | NULL | auto_increment |
| name | varchar(191) | NO | | NULL | |
| base_urls | json | NO | | NULL | |
| default_model | varchar(191) | NO | | NULL | |
| requires_auth | tinyint(1) | NO | | 1 | |
| auth_header | varchar(191) | NO | | NULL | |
| created_at | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| updated_at | datetime(3) | YES | | NULL | |

### _prisma_migrations

| Column | Type | Null | Key | Default | Extra |
|--------|------|------|-----|---------|-------|
| id | varchar(36) | NO | PRI | NULL | |
| checksum | varchar(64) | NO | | NULL | |
| finished_at | datetime(3) | YES | | NULL | |
| migration_name | varchar(255) | NO | | NULL | |
| rolled_back_at | datetime(3) | YES | | NULL | |
| started_at | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| applied_steps_count | int | NO | | 0 | |

## Relationships

```
┌────────────┐     ┌────────────┐     ┌────────────┐
│   users    │────▶│ ai_connections │────▶│ ai_providers │
└────────────┘     └────────────┘     └────────────┘
      │                   │
      │                   │
      ▼                   ▼
┌────────────┐     ┌────────────┐
│   chats    │────▶│chat_messages│
└────────────┘     └────────────┘
      │
      │
      ▼
┌────────────┐
│  prompts   │
└────────────┘
```

## Key Points

1. **User Management**: The `users` table stores all user information, including authentication details and profile data.

2. **AI Connections**: The `ai_connections` table stores API keys and provider information for each user's AI services.

3. **Chat System**: The `chats` and `chat_messages` tables handle the chat functionality, allowing users to have multiple conversations with AI providers.

4. **Prompt Management**: The `prompts` table stores user-created prompts that can be reused in conversations.

5. **AI Provider Configuration**: The `ai_providers` table stores configuration information for different AI service providers.

6. **Data Consistency**: Foreign key relationships ensure data integrity between related tables.

7. **Timestamps**: Most tables include `created_at` and `updated_at` timestamps for tracking when records were created or modified.

8. **System Flag**: The `system_flag` column in several tables indicates whether records were created by the Wingman app or the Pen app.

## Security Considerations

- Passwords are stored as plain text in the `password` column. In a production environment, these should be hashed using a secure hashing algorithm.
- API keys in the `ai_connections` table are stored as plain text. These should be encrypted or stored in a secure vault in a production environment.
- Email addresses are unique to prevent duplicate user accounts.
