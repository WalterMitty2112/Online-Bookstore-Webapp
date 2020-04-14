PGDMP     (    (                x        	   Bookstore    12.2    12.2 !    &           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            '           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            (           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            )           1262    33141 	   Bookstore    DATABASE     �   CREATE DATABASE "Bookstore" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'French_France.1252' LC_CTYPE = 'French_France.1252';
    DROP DATABASE "Bookstore";
                postgres    false                        2615    33189    allops    SCHEMA        CREATE SCHEMA allops;
    DROP SCHEMA allops;
                postgres    false            *           0    0    SCHEMA allops    COMMENT     I   COMMENT ON SCHEMA allops IS 'Handles all operations in a single schema';
                   postgres    false    8            �            1255    33190 @   p_cuser(character varying, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE allops.p_cuser(p_name character varying, p_username character varying, p_password character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$BEGIN
    if ( select exists (select 1 from allops.user where user_username = p_username) ) THEN
     
        select 'Username Exists !!';
     
    ELSE
     
        insert into tbl_user ( user_name, user_username, user_pswd )
        values( p_name, p_username, p_password );
     
    END IF;
END; 
$$;
 u   DROP PROCEDURE allops.p_cuser(p_name character varying, p_username character varying, p_password character varying);
       allops          postgres    false    8            �            1255    33237 0   global_regexp_search(text, text[], text[], text)    FUNCTION     W  CREATE FUNCTION public.global_regexp_search(search_re text, param_tables text[] DEFAULT '{}'::text[], param_schemas text[] DEFAULT '{public}'::text[], progress text DEFAULT NULL::text) RETURNS TABLE(schemaname text, tablename text, columnname text, columnvalue text, rowctid tid)
    LANGUAGE plpgsql
    AS $$
declare
  query text;
begin
  FOR schemaname,tablename IN
      SELECT table_schema, table_name
      FROM information_schema.tables t
      WHERE (t.table_name=ANY(param_tables) OR param_tables='{}')
        AND t.table_schema=ANY(param_schemas)
        AND t.table_type='BASE TABLE'
  LOOP
    IF (progress in ('tables','all')) THEN
      raise info '%', format('Searching globally in table: %I.%I',
         schemaname, tablename);
    END IF;

    query := format('SELECT ctid FROM %I.%I AS t WHERE cast(t.* as text) ~ %L',
	    schemaname,
	    tablename,
	    search_re);
    FOR rowctid IN EXECUTE query
    LOOP
      FOR columnname IN
	  SELECT column_name
	  FROM information_schema.columns
	  WHERE table_name=tablename
	    AND table_schema=schemaname
      LOOP
	query := format('SELECT %I FROM %I.%I WHERE cast(%I as text) ~ %L AND ctid=%L',
	  columnname, schemaname, tablename, columnname, search_re, rowctid);
        EXECUTE query INTO columnvalue;
	IF columnvalue IS NOT NULL THEN
	  IF (progress in ('hits', 'all')) THEN
	    raise info '%', format('Found in %I.%I.%I at ctid %s, value: ''%s''',
		   schemaname, tablename, columnname, rowctid, columnvalue);
	  END IF;
	  RETURN NEXT;
	END IF;
      END LOOP; -- for columnname
    END LOOP; -- for rowctid
  END LOOP; -- for table
END;
$$;
 u   DROP FUNCTION public.global_regexp_search(search_re text, param_tables text[], param_schemas text[], progress text);
       public          postgres    false            �            1255    33236 )   global_search(text, text[], text[], text)    FUNCTION       CREATE FUNCTION public.global_search(search_term text, param_tables text[] DEFAULT '{book}'::text[], param_schemas text[] DEFAULT '{allops}'::text[], progress text DEFAULT NULL::text) RETURNS TABLE(schemaname text, tablename text, columnname text, rowctid tid)
    LANGUAGE plpgsql
    AS $$
declare
  query text;
  hit boolean;
begin
  FOR schemaname,tablename IN
      SELECT table_schema, table_name
      FROM information_schema.tables t
      WHERE (t.table_name=ANY(param_tables) OR param_tables='{}')
        AND t.table_schema=ANY(param_schemas)
        AND t.table_type='BASE TABLE'
  LOOP
    IF (progress in ('tables','all')) THEN
      raise info '%', format('Searching globally in table: %I.%I',
         schemaname, tablename);
    END IF;

    query := format('SELECT ctid FROM %I.%I AS t WHERE strpos(cast(t.* as text), %L) > 0',
	    schemaname,
	    tablename,
	    search_term);
    FOR rowctid IN EXECUTE query
    LOOP
      FOR columnname IN
	  SELECT column_name
	  FROM information_schema.columns
	  WHERE table_name=tablename
	    AND table_schema=schemaname
      LOOP
	query := format('SELECT true FROM %I.%I WHERE cast(%I as text)=%L AND ctid=%L',
	  schemaname, tablename, columnname, search_term, rowctid);
        EXECUTE query INTO hit;
	IF hit THEN
	  IF (progress in ('hits', 'all')) THEN
	    raise info '%', format('Found in %I.%I.%I at ctid %s',
		   schemaname, tablename, columnname, rowctid);
	  END IF;
	  RETURN NEXT;
	END IF;
      END LOOP; -- for columnname
    END LOOP; -- for rowctid
  END LOOP; -- for table
END;
$$;
 p   DROP FUNCTION public.global_search(search_term text, param_tables text[], param_schemas text[], progress text);
       public          postgres    false            �            1259    33191    book    TABLE     �  CREATE TABLE allops.book (
    bk_name character varying NOT NULL,
    bk_auth character varying,
    bk_isbn bigint,
    bk_genre character varying,
    bk_pages bigint,
    bk_numauth bigint,
    bk_price bigint,
    bk_type character varying,
    bk_lang character varying,
    bk_pub character varying,
    bk_remain bigint,
    bk_id character varying(45),
    bk_sold bigint,
    bk_published character varying
);
    DROP TABLE allops.book;
       allops         heap    postgres    false    8            +           0    0 
   TABLE book    COMMENT     @   COMMENT ON TABLE allops.book IS 'stores all info on each book';
          allops          postgres    false    203            ,           0    0    COLUMN book.bk_id    COMMENT     ;   COMMENT ON COLUMN allops.book.bk_id IS 'id for each book';
          allops          postgres    false    203            �            1259    33197    checkout    TABLE     �   CREATE TABLE allops.checkout (
    ch_userid bigint NOT NULL,
    ch_billaddr character varying,
    ch_shipaddr character varying,
    ch_books character varying[]
);
    DROP TABLE allops.checkout;
       allops         heap    postgres    false    8            -           0    0    TABLE checkout    COMMENT     <   COMMENT ON TABLE allops.checkout IS 'checkout per user_id';
          allops          postgres    false    204            �            1259    33203    order_track    TABLE     �   CREATE TABLE allops.order_track (
    order_num bigint NOT NULL,
    last_loc character varying,
    track_history character varying[],
    track_num character varying
);
    DROP TABLE allops.order_track;
       allops         heap    postgres    false    8            .           0    0    TABLE order_track    COMMENT     E   COMMENT ON TABLE allops.order_track IS 'tracking info for an order';
          allops          postgres    false    205            �            1259    33209 	   publisher    TABLE     �   CREATE TABLE allops.publisher (
    p_id bigint NOT NULL,
    p_name character varying,
    p_addr character varying,
    p_email character varying,
    p_phnum bigint,
    p_bacct bigint
);
    DROP TABLE allops.publisher;
       allops         heap    postgres    false    8            /           0    0    TABLE publisher    COMMENT     A   COMMENT ON TABLE allops.publisher IS 'table for all publishers';
          allops          postgres    false    206            �            1259    33215    user    TABLE       CREATE TABLE allops."user" (
    user_id bigint NOT NULL,
    user_name character varying(45),
    user_username character varying(45),
    user_pswd character varying(45),
    user_biladdr character varying,
    user_shipaddr character varying,
    user_email character varying
);
    DROP TABLE allops."user";
       allops         heap    postgres    false    8            0           0    0    TABLE "user"    COMMENT     6   COMMENT ON TABLE allops."user" IS 'stores all users';
          allops          postgres    false    207            1           0    0    COLUMN "user".user_biladdr    COMMENT     M   COMMENT ON COLUMN allops."user".user_biladdr IS 'billing info for the user';
          allops          postgres    false    207            2           0    0    COLUMN "user".user_shipaddr    COMMENT     O   COMMENT ON COLUMN allops."user".user_shipaddr IS 'shipping info for the user';
          allops          postgres    false    207                      0    33191    book 
   TABLE DATA           �   COPY allops.book (bk_name, bk_auth, bk_isbn, bk_genre, bk_pages, bk_numauth, bk_price, bk_type, bk_lang, bk_pub, bk_remain, bk_id, bk_sold, bk_published) FROM stdin;
    allops          postgres    false    203   B1                  0    33197    checkout 
   TABLE DATA           Q   COPY allops.checkout (ch_userid, ch_billaddr, ch_shipaddr, ch_books) FROM stdin;
    allops          postgres    false    204   ]2       !          0    33203    order_track 
   TABLE DATA           T   COPY allops.order_track (order_num, last_loc, track_history, track_num) FROM stdin;
    allops          postgres    false    205   �2       "          0    33209 	   publisher 
   TABLE DATA           T   COPY allops.publisher (p_id, p_name, p_addr, p_email, p_phnum, p_bacct) FROM stdin;
    allops          postgres    false    206   �2       #          0    33215    user 
   TABLE DATA           w   COPY allops."user" (user_id, user_name, user_username, user_pswd, user_biladdr, user_shipaddr, user_email) FROM stdin;
    allops          postgres    false    207   3       �
           2606    33222    book book_pkey 
   CONSTRAINT     Q   ALTER TABLE ONLY allops.book
    ADD CONSTRAINT book_pkey PRIMARY KEY (bk_name);
 8   ALTER TABLE ONLY allops.book DROP CONSTRAINT book_pkey;
       allops            postgres    false    203            �
           2606    33224    checkout checkout_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY allops.checkout
    ADD CONSTRAINT checkout_pkey PRIMARY KEY (ch_userid);
 @   ALTER TABLE ONLY allops.checkout DROP CONSTRAINT checkout_pkey;
       allops            postgres    false    204            �
           2606    33226    order_track order_track_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY allops.order_track
    ADD CONSTRAINT order_track_pkey PRIMARY KEY (order_num);
 F   ALTER TABLE ONLY allops.order_track DROP CONSTRAINT order_track_pkey;
       allops            postgres    false    205            �
           2606    33228    publisher publisher_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY allops.publisher
    ADD CONSTRAINT publisher_pkey PRIMARY KEY (p_id);
 B   ALTER TABLE ONLY allops.publisher DROP CONSTRAINT publisher_pkey;
       allops            postgres    false    206            �
           2606    33230    user user_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY allops."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY allops."user" DROP CONSTRAINT user_pkey;
       allops            postgres    false    207            �
           2606    33231    checkout user    FK CONSTRAINT     v   ALTER TABLE ONLY allops.checkout
    ADD CONSTRAINT "user" FOREIGN KEY (ch_userid) REFERENCES allops."user"(user_id);
 9   ALTER TABLE ONLY allops.checkout DROP CONSTRAINT "user";
       allops          postgres    false    204    207    2719                 x�m��n�0�g�)��$�?�:?@�M�.��Ƃɐe�y��]������2m2�`G�3�^^�⠝�}@���3n{}�A5-+eU*�'��%o��$<!����'�WmF����� 9�����|��LS���"��RU�-�`��)����eM#�Nr�������<��0f�J� �����	y�p��l?cI���w�L���y ������ldC\�F��V�9?_�կ���_X}� �T�ߛ�(� �Br�          !   x�3426���j�ҼT+�Z.St�=... ��
�      !   R   x�3��/�L��S(.I,I�V
��,(HMQH+��U(O,J��/-NU�Q�IM+Q�GR�T����k�]����Q��W����� �s�      "      x������ � �      #   �   x����
�0���S��`n�w��śGA�Z��&c]����:ԓ����M���w&��`��������h�������+;�J���}��ؠC ��-"aJk��~Qo��K$JY����h����s�iռЙ���6��x�x���K@<�<H���:H��R����0����`Ǒ�Q��%uv���V�y�S��z���H     