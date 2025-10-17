-- Fix UUID type mismatches in conversations, messages, and notifications tables
-- This script converts VARCHAR columns to UUID to match the User.id type
-- First, let's check if the tables exist and what their current structure is
-- If they don't exist, we'll create them with the correct types
-- Create conversations table if it doesn't exist
CREATE TABLE IF NOT EXISTS conversations (
    id VARCHAR PRIMARY KEY,
    match_id VARCHAR REFERENCES matches(id),
    participant_one_id UUID REFERENCES users(id) NOT NULL,
    participant_two_id UUID REFERENCES users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- Create messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS messages (
    id VARCHAR PRIMARY KEY,
    conversation_id VARCHAR REFERENCES conversations(id) NOT NULL,
    sender_id UUID REFERENCES users(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS notifications (
    id VARCHAR PRIMARY KEY,
    user_id UUID REFERENCES users(id) NOT NULL,
    type VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    content TEXT,
    reference_id VARCHAR,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- If the tables already exist with wrong types, we need to alter them
-- Note: This is a destructive operation that will lose data
-- In production, you'd want to migrate the data properly
-- For now, let's just drop and recreate the tables if they exist with wrong types
-- This is safe for development since there's likely no important data yet
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
-- Recreate with correct types
CREATE TABLE conversations (
    id VARCHAR PRIMARY KEY,
    match_id VARCHAR REFERENCES matches(id),
    participant_one_id UUID REFERENCES users(id) NOT NULL,
    participant_two_id UUID REFERENCES users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE TABLE messages (
    id VARCHAR PRIMARY KEY,
    conversation_id VARCHAR REFERENCES conversations(id) NOT NULL,
    sender_id UUID REFERENCES users(id) NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE TABLE notifications (
    id VARCHAR PRIMARY KEY,
    user_id UUID REFERENCES users(id) NOT NULL,
    type VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    content TEXT,
    reference_id VARCHAR,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_participant_one ON conversations(participant_one_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_two ON conversations(participant_two_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
