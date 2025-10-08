-- Fix user passwords with proper bcrypt hashes
-- Admin password: Admin123!
UPDATE users
SET
    hashed_password = '$2b$12$qNmeQvIk59DIpLrbZOAiJO8ed4mySip4i3Q8P67S9gvWw9UCRV8RW'
WHERE
    email = 'admin@lostfound.com';

-- Test user passwords: Test123!
UPDATE users
SET
    hashed_password = '$2b$12$U9vbM5QtbPLPrPUi6yjP2ek0ZeZYQ5QoSbLGHX2mpOXK4PhUi6eem'
WHERE
    email LIKE 'user%@example.com';

-- Verify the updates
SELECT
    email,
    LEFT (hashed_password, 10) as hash_preview,
    LENGTH (hashed_password) as hash_length
FROM
    users
WHERE
    email IN (
        'admin@lostfound.com',
        'user1@example.com',
        'user2@example.com',
        'john.doe@example.com'
    )
ORDER BY
    email;