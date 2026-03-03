# Database Structure

## wingman_db.users Table

| Field | Type | Null | Key | Default | Extra |
| --- | --- | --- | --- | --- | --- |
| id | int | NO | PRI | null | auto_increment |
| name | varchar(191) | NO | | null | |
| email | varchar(191) | NO | UNI | null | |
| password | varchar(191) | NO | | null | |
| profileImage | longtext | YES | | null | |
| createdAt | datetime(3) | NO | | CURRENT_TIMESTAMP(3) | DEFAULT_GENERATED |
| system_flag | varchar(20) | NO | | WINGMAN | |
| pen_content_history | int | NO | | 10 | |

## Total Users
15 users currently in the database
