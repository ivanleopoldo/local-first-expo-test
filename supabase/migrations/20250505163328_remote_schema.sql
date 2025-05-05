

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."create_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_created_at" timestamp with time zone, "todo_updated_at" timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  new_id uuid;
BEGIN
  INSERT INTO todos(
    id,
    title,
    is_completed,
    created_at,
    updated_at,
    server_created_at,
    last_modified_at
  ) VALUES (
    todo_id,
    todo_title,
    todo_is_completed,
    todo_created_at,
    todo_updated_at,
    now(),
    now() + interval '1 microsecond'
  ) RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;


ALTER FUNCTION "public"."create_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_created_at" timestamp with time zone, "todo_updated_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."epoch_to_timestamp"("epoch" "text") RETURNS timestamp with time zone
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN timestamp with time zone 'epoch' + (
    (epoch :: bigint) / 1000
  ) * interval '1 second';
END;
$$;


ALTER FUNCTION "public"."epoch_to_timestamp"("epoch" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pull"("last_pulled_at" bigint DEFAULT 0) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  _ts TIMESTAMP WITH TIME ZONE;
  _todos JSONB;
BEGIN
  _ts := to_timestamp(last_pulled_at / 1000);
  

  SELECT jsonb_build_object(
    'created', '[]'::jsonb,
    'updated', coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', todo.id,
          'title', todo.title,
          'is_completed', todo.is_completed,
          'created_at', timestamp_to_epoch(todo.created_at),
          'updated_at', timestamp_to_epoch(todo.updated_at)
        )
      ) FILTER (
        WHERE todo.deleted_at IS NULL AND todo.last_modified_at > _ts
      ), '[]'::jsonb
    ),
    'deleted', coalesce(
      jsonb_agg(to_jsonb(todo.id)) FILTER (
        WHERE todo.deleted_at IS NOT NULL AND todo.last_modified_at > _ts
      ), '[]'::jsonb
    )
  ) INTO _todos
  FROM todos todo;

  RETURN jsonb_build_object(
    'changes', jsonb_build_object(
      'todos', _todos
    ),
    'timestamp', timestamp_to_epoch(now())
  );
END;
$$;


ALTER FUNCTION "public"."pull"("last_pulled_at" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."push"("changes" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
        new_todo jsonb;
        updated_todo jsonb;
BEGIN
        for new_todo in 
        select jsonb_array_elements((changes->'todos'->'created')) loop perform create_todo(
                (new_todo->>'id')::uuid,
                (new_todo->>'title'),
                (new_todo->>'is_completed')::boolean,
                epoch_to_timestamp(new_todo->>'created_at'),
                epoch_to_timestamp(new_todo->>'updated_at')
        );
        END loop;
        WITH changes_data as (
                select jsonb_array_elements_text(changes->'todos'->'deleted')::uuid as deleted
        )
        UPDATE todos
        SET deleted_at = now(),
                last_modified_at = now()
        FROM changes_data
        WHERE todos.id = changes_data.deleted;

        FOR updated_todo IN select jsonb_array_elements((changes->'todos'->'updated')) loop perform update_todo(
                (updated_todo->>'id')::uuid,
                (updated_todo->>'title'),
                (updated_todo->>'is_completed')::boolean,
                epoch_to_timestamp(updated_todo->>'updated_at')
        );
        END loop;
END;
$$;


ALTER FUNCTION "public"."push"("changes" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."timestamp_to_epoch"("ts" timestamp with time zone) RETURNS bigint
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN (extract(epoch from ts) * 1000) :: BIGINT;
END;
$$;


ALTER FUNCTION "public"."timestamp_to_epoch"("ts" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_game"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE todos
  SET title = todo_title,
      is_completed = todo_is_completed,
      updated_at = todo_updated_at,
      last_modified_at = now()
  WHERE id = todo_id;
  RETURN todo_id;
END;
$$;


ALTER FUNCTION "public"."update_game"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE todos
  SET title = todo_title,
      is_completed = todo_is_completed,
      updated_at = todo_updated_at,
      last_modified_at = now()
  WHERE id = todo_id;
  RETURN todo_id;
END;
$$;


ALTER FUNCTION "public"."update_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."todos" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" character varying NOT NULL,
    "is_completed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted_at" timestamp with time zone,
    "server_created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_modified_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."todos" OWNER TO "postgres";


ALTER TABLE ONLY "public"."todos"
    ADD CONSTRAINT "todos_pkey" PRIMARY KEY ("id");





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































GRANT ALL ON FUNCTION "public"."create_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_created_at" timestamp with time zone, "todo_updated_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."create_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_created_at" timestamp with time zone, "todo_updated_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_created_at" timestamp with time zone, "todo_updated_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."epoch_to_timestamp"("epoch" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."epoch_to_timestamp"("epoch" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."epoch_to_timestamp"("epoch" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pull"("last_pulled_at" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pull"("last_pulled_at" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pull"("last_pulled_at" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."push"("changes" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."push"("changes" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."push"("changes" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."timestamp_to_epoch"("ts" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."timestamp_to_epoch"("ts" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."timestamp_to_epoch"("ts" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_game"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."update_game"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_game"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."update_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_todo"("todo_id" "uuid", "todo_title" character varying, "todo_is_completed" boolean, "todo_updated_at" timestamp with time zone) TO "service_role";


















GRANT ALL ON TABLE "public"."todos" TO "anon";
GRANT ALL ON TABLE "public"."todos" TO "authenticated";
GRANT ALL ON TABLE "public"."todos" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
