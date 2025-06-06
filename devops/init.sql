-- Create Data Schema
CREATE SCHEMA dlang_data;

-- Create User
-- CREATE USER dlang_user WITH PASSWORD 'dlang_password';

-- Grant Permissions
GRANT ALL PRIVILEGES ON SCHEMA dlang_data TO dlang_user;

-- Create Tables
CREATE TABLE IF NOT EXISTS dlang_data.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    age INTEGER NOT NULL,
    country VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX idx_users_email ON dlang_data.users (email);
CREATE INDEX idx_users_username ON dlang_data.users (username);

-- Create Functions
CREATE FUNCTION insert_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.created_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE FUNCTION update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Triggers
CREATE TRIGGER insert_users_timestamp
    BEFORE UPDATE ON dlang_data.users
    FOR EACH ROW EXECUTE FUNCTION insert_timestamp();
CREATE TRIGGER update_users_timestamp
    BEFORE UPDATE ON dlang_data.users
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
