--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: message_hashes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE message_hashes (
    mhash character varying(64) NOT NULL,
    subscription_id integer NOT NULL,
    "time" timestamp with time zone DEFAULT now()
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriptions (
    id integer NOT NULL,
    url text NOT NULL
);


--
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE subscriptions_id_seq OWNED BY subscriptions.id;


--
-- Name: subscriptions_users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriptions_users (
    user_id integer NOT NULL,
    subscription_id integer NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    jid character varying(255) NOT NULL,
    access integer DEFAULT 0 NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions ALTER COLUMN id SET DEFAULT nextval('subscriptions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: message_hash_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY message_hashes
    ADD CONSTRAINT message_hash_pkey PRIMARY KEY (mhash, subscription_id);


--
-- Name: subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: subscriptions_users_idx_subscription_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX subscriptions_users_idx_subscription_id ON subscriptions_users USING btree (subscription_id);


--
-- Name: subscriptions_users_idx_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX subscriptions_users_idx_user_id ON subscriptions_users USING btree (user_id);


--
-- Name: users_idx_jid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_idx_jid ON users USING btree (jid);


--
-- Name: message_hashes_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY message_hashes
    ADD CONSTRAINT message_hashes_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions_users_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions_users
    ADD CONSTRAINT subscriptions_users_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY subscriptions_users
    ADD CONSTRAINT subscriptions_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

