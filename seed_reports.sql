-- Seed Reports Data for Lost & Found Database
-- This script creates 30 sample reports (15 LOST + 15 FOUND) for testing

-- Get a user ID to use as owner (using first regular user)
DO $$
DECLARE
    user_ids UUID[];
    current_user_id UUID;
    report_id UUID;
    occurred_date TIMESTAMP;
    i INT;
BEGIN
    -- Get all user IDs except admin
    SELECT ARRAY_AGG(id) INTO user_ids FROM users WHERE role = 'user' LIMIT 10;
    
    -- LOST Reports
    FOR i IN 1..15 LOOP
        current_user_id := user_ids[((i - 1) % array_length(user_ids, 1)) + 1];
        report_id := gen_random_uuid();
        occurred_date := NOW() - (RANDOM() * INTERVAL '60 days');
        
        INSERT INTO reports (
            id, owner_id, type, status, title, description,
            category, colors, occurred_at,
            location_city, location_address,
            reward_offered, is_resolved,
            created_at, updated_at
        ) VALUES (
            report_id,
            current_user_id,
            'LOST',
            CASE WHEN RANDOM() < 0.7 THEN 'APPROVED' ELSE 'PENDING' END,
            CASE i
                WHEN 1 THEN 'Lost iPhone 14 Pro - #001'
                WHEN 2 THEN 'Missing Gold Wedding Ring - #002'
                WHEN 3 THEN 'Lost Brown Leather Wallet - #003'
                WHEN 4 THEN 'Missing Car Keys - #004'
                WHEN 5 THEN 'Lost Black Nike Backpack - #005'
                WHEN 6 THEN 'Missing Passport - #006'
                WHEN 7 THEN 'Lost Pet Cat - #007'
                WHEN 8 THEN 'Missing Laptop - #008'
                WHEN 9 THEN 'Lost Prescription Glasses - #009'
                WHEN 10 THEN 'Missing Wristwatch - #010'
                WHEN 11 THEN 'Lost Student ID Card - #011'
                WHEN 12 THEN 'Missing Handbag - #012'
                WHEN 13 THEN 'Lost Blue Umbrella - #013'
                WHEN 14 THEN 'Missing Headphones - #014'
                WHEN 15 THEN 'Lost House Keys - #015'
            END,
            CASE i
                WHEN 1 THEN 'Lost my black iPhone 14 Pro near the bus station. Has a cracked screen protector and blue case. Last seen at Fort Railway Station.'
                WHEN 2 THEN 'Lost my wedding ring at Galle Face beach. Simple gold band with engraving ''Forever'' inside. Huge sentimental value.'
                WHEN 3 THEN 'Brown leather wallet with multiple cards, driving license, and some cash. Lost near Majestic City shopping mall.'
                WHEN 4 THEN 'Lost Toyota car keys with blue keychain near Liberty Plaza. Has house keys attached. Very urgent!'
                WHEN 5 THEN 'Black Nike backpack with laptop inside. Lost at Fort Railway Station. Has name tag with my contact.'
                WHEN 6 THEN 'Sri Lankan passport (red cover) lost at Bandaranaike Airport departure hall. Urgent need for travel!'
                WHEN 7 THEN 'Orange tabby cat named Whiskers. Lost near Viharamahadevi Park. Very friendly and wearing blue collar.'
                WHEN 8 THEN 'Dell Latitude laptop in black bag. Lost at Coffee Bean Bambalapitiya. Has company stickers on it.'
                WHEN 9 THEN 'Black frame prescription glasses in blue case. Lost at Odel Colombo 7. I can''t see without them!'
                WHEN 10 THEN 'Silver Casio G-Shock watch with blue dial. Sentimental value - gift from father. Lost at gym.'
                WHEN 11 THEN 'University of Colombo student ID. Name: Sarah Fernando. Lost in library area. Need for exams.'
                WHEN 12 THEN 'Red leather handbag with phone and makeup inside. Lost in taxi near Crescat Boulevard.'
                WHEN 13 THEN 'Blue folding umbrella with wooden handle. Left at Nawaloka Hospital reception area.'
                WHEN 14 THEN 'Black Sony wireless headphones in carrying case. Lost on bus route 138 going to Nugegoda.'
                WHEN 15 THEN 'Set of 5 keys on red keychain. Lost near Keells Super Bambalapitiya. Includes car and house keys.'
            END,
            CASE i
                WHEN 1 THEN 'Electronics'
                WHEN 2 THEN 'Jewelry'
                WHEN 3 THEN 'Wallets'
                WHEN 4 THEN 'Keys'
                WHEN 5 THEN 'Bags'
                WHEN 6 THEN 'Documents'
                WHEN 7 THEN 'Pets'
                WHEN 8 THEN 'Electronics'
                WHEN 9 THEN 'Other'
                WHEN 10 THEN 'Jewelry'
                WHEN 11 THEN 'Documents'
                WHEN 12 THEN 'Bags'
                WHEN 13 THEN 'Other'
                WHEN 14 THEN 'Electronics'
                WHEN 15 THEN 'Keys'
            END,
            CASE i
                WHEN 1 THEN ARRAY['Black', 'Blue']
                WHEN 2 THEN ARRAY['Gold']
                WHEN 3 THEN ARRAY['Brown']
                WHEN 4 THEN ARRAY['Silver', 'Blue']
                WHEN 5 THEN ARRAY['Black']
                WHEN 6 THEN ARRAY['Red']
                WHEN 7 THEN ARRAY['Orange']
                WHEN 8 THEN ARRAY['Black', 'Silver']
                WHEN 9 THEN ARRAY['Black', 'Blue']
                WHEN 10 THEN ARRAY['Silver', 'Blue']
                WHEN 11 THEN ARRAY['Blue', 'White']
                WHEN 12 THEN ARRAY['Red']
                WHEN 13 THEN ARRAY['Blue', 'Brown']
                WHEN 14 THEN ARRAY['Black']
                WHEN 15 THEN ARRAY['Silver', 'Red']
            END,
            occurred_date,
            CASE MOD(i, 5)
                WHEN 0 THEN 'Colombo'
                WHEN 1 THEN 'Kandy'
                WHEN 2 THEN 'Galle'
                WHEN 3 THEN 'Negombo'
                WHEN 4 THEN 'Matara'
            END,
            CASE MOD(i, 5)
                WHEN 0 THEN '256 Galle Road, Colombo 03'
                WHEN 1 THEN '145 Kandy Road, Colombo 07'
                WHEN 2 THEN '89 Duplication Road, Colombo 04'
                WHEN 3 THEN '432 Union Place, Colombo 02'
                WHEN 4 THEN '67 Baseline Road, Colombo 09'
            END,
            i % 3 = 0,  -- reward_offered for every 3rd item
            FALSE,  -- not resolved
            NOW(),
            NOW()
        );
    END LOOP;
    
    -- FOUND Reports
    FOR i IN 1..15 LOOP
        current_user_id := user_ids[((i - 1) % array_length(user_ids, 1)) + 1];
        report_id := gen_random_uuid();
        occurred_date := NOW() - (RANDOM() * INTERVAL '60 days');
        
        INSERT INTO reports (
            id, owner_id, type, status, title, description,
            category, colors, occurred_at,
            location_city, location_address,
            reward_offered, is_resolved,
            created_at, updated_at
        ) VALUES (
            report_id,
            current_user_id,
            'FOUND',
            CASE WHEN RANDOM() < 0.7 THEN 'APPROVED' ELSE 'PENDING' END,
            CASE i
                WHEN 1 THEN 'Found iPhone - #016'
                WHEN 2 THEN 'Found Gold Ring - #017'
                WHEN 3 THEN 'Found Wallet - #018'
                WHEN 4 THEN 'Found Car Keys - #019'
                WHEN 5 THEN 'Found Backpack - #020'
                WHEN 6 THEN 'Found Passport - #021'
                WHEN 7 THEN 'Found Cat - #022'
                WHEN 8 THEN 'Found Laptop Bag - #023'
                WHEN 9 THEN 'Found Glasses - #024'
                WHEN 10 THEN 'Found Watch - #025'
                WHEN 11 THEN 'Found Student ID - #026'
                WHEN 12 THEN 'Found Handbag - #027'
                WHEN 13 THEN 'Found Umbrella - #028'
                WHEN 14 THEN 'Found Headphones - #029'
                WHEN 15 THEN 'Found Keys - #030'
            END,
            CASE i
                WHEN 1 THEN 'Found an iPhone 14 near bus stop. Screen locked but receiving calls. Want to return to owner.'
                WHEN 2 THEN 'Found a gold ring on Negombo beach this morning. Looks like a wedding band with engraving.'
                WHEN 3 THEN 'Found brown wallet near Majestic City with ID cards and cash. Contact to claim with ID proof.'
                WHEN 4 THEN 'Found Toyota keys with blue keychain near Liberty Plaza parking. No contact info attached.'
                WHEN 5 THEN 'Found black backpack at railway station. Contains laptop and textbooks. Holding at security.'
                WHEN 6 THEN 'Found Sri Lankan passport near airport departure hall. Will hand to lost & found counter.'
                WHEN 7 THEN 'Found friendly orange cat near park. Well-fed, wearing collar. Seems to be someone''s pet.'
                WHEN 8 THEN 'Found black laptop bag in taxi. Contains Dell laptop and charger. Driver keeping it safe.'
                WHEN 9 THEN 'Found prescription glasses in blue case near Odel. Strong prescription, owner must need them.'
                WHEN 10 THEN 'Found silver watch near gym locker room. Casio brand with blue face. Expensive model.'
                WHEN 11 THEN 'Found University of Colombo student ID. Will keep at main office. Student can collect with proof.'
                WHEN 12 THEN 'Found red leather handbag in taxi. Contains phone and wallet. Trying to contact owner.'
                WHEN 13 THEN 'Found blue umbrella at hospital reception. Nice wooden handle. Still there if unclaimed.'
                WHEN 14 THEN 'Found Sony wireless headphones on bus. In black carrying case with charging cable.'
                WHEN 15 THEN 'Found set of house keys on red keychain near Keells. 5 keys total. No identifying info.'
            END,
            CASE i
                WHEN 1 THEN 'Electronics'
                WHEN 2 THEN 'Jewelry'
                WHEN 3 THEN 'Wallets'
                WHEN 4 THEN 'Keys'
                WHEN 5 THEN 'Bags'
                WHEN 6 THEN 'Documents'
                WHEN 7 THEN 'Pets'
                WHEN 8 THEN 'Electronics'
                WHEN 9 THEN 'Other'
                WHEN 10 THEN 'Jewelry'
                WHEN 11 THEN 'Documents'
                WHEN 12 THEN 'Bags'
                WHEN 13 THEN 'Other'
                WHEN 14 THEN 'Electronics'
                WHEN 15 THEN 'Keys'
            END,
            CASE i
                WHEN 1 THEN ARRAY['Black']
                WHEN 2 THEN ARRAY['Gold']
                WHEN 3 THEN ARRAY['Brown']
                WHEN 4 THEN ARRAY['Silver', 'Blue']
                WHEN 5 THEN ARRAY['Black']
                WHEN 6 THEN ARRAY['Red']
                WHEN 7 THEN ARRAY['Orange']
                WHEN 8 THEN ARRAY['Black']
                WHEN 9 THEN ARRAY['Black', 'Blue']
                WHEN 10 THEN ARRAY['Silver', 'Blue']
                WHEN 11 THEN ARRAY['Blue', 'White']
                WHEN 12 THEN ARRAY['Red']
                WHEN 13 THEN ARRAY['Blue']
                WHEN 14 THEN ARRAY['Black']
                WHEN 15 THEN ARRAY['Silver', 'Red']
            END,
            occurred_date,
            CASE MOD(i, 5)
                WHEN 0 THEN 'Colombo'
                WHEN 1 THEN 'Kandy'
                WHEN 2 THEN 'Galle'
                WHEN 3 THEN 'Negombo'
                WHEN 4 THEN 'Matara'
            END,
            CASE MOD(i, 5)
                WHEN 0 THEN '256 Galle Road, Colombo 03'
                WHEN 1 THEN '145 Kandy Road, Colombo 07'
                WHEN 2 THEN '89 Duplication Road, Colombo 04'
                WHEN 3 THEN '432 Union Place, Colombo 02'
                WHEN 4 THEN '67 Baseline Road, Colombo 09'
            END,
            FALSE,  -- no reward for found items
            FALSE,  -- not resolved
            NOW(),
            NOW()
        );
    END LOOP;
    
    RAISE NOTICE '✅ Successfully created 30 reports (15 LOST + 15 FOUND)';
END $$;

-- Verify the seeding
SELECT 
    type,
    status,
    COUNT(*) as count
FROM reports
GROUP BY type, status
ORDER BY type, status;
