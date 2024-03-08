-- Mandatory Project (ADVANCED W3-W4 | Submitted on 6th Oct 2023 3:00 am)
-- 1. How many times does the average user post?
WITH post_per_user AS (									-- USING CTE
  SELECT user_id, COUNT(*) AS user_count
  FROM photos
  GROUP BY user_id
)
SELECT ROUND(AVG(user_count), 2) AS average_user_post	-- USING ROUND FUNCTION
FROM post_per_user;

-- 2. Find the top 5 most used hashtags.
SELECT tag_name, COUNT(*) AS usage_count
FROM tags AS t
JOIN photo_tags AS pt ON t.id = pt.tag_id 
GROUP BY tag_name
ORDER BY usage_count DESC
LIMIT 5;

-- 3. Find users who have liked every single photo on the site.
SELECT u.username
FROM USERS u
WHERE u.id IN (
SELECT l.user_id
FROM LIKES l
LEFT JOIN (SELECT DISTINCT p.id
FROM PHOTOS p) AS all_photos ON l.photo_id = all_photos.id
GROUP BY l.user_id
HAVING COUNT(all_photos.id) = COUNT(l.photo_id)
);

-- 4. Retrieve a list of users along with their usernames and the rank of their 
-- account creation, ordered by the creation date in ascending order.
SELECT id, username,
RANK() OVER (ORDER BY created_at) AS account_creation_rank
FROM USERS;

-- 5. List the comments made on photos with their comment texts, photo URLs, and 
-- usernames of users who posted the comments. Include the comment count for each photo
SELECT c.id AS comment_id, C.comment_text, P.image_url, U.username,
COUNT(C.id) OVER (PARTITION BY P.id) AS comment_count
FROM COMMENTS C
JOIN PHOTOS P ON C.photo_id = P.id
JOIN USERS U ON C.user_id = U.id
ORDER BY P.id, comment_count DESC;
    
-- 6.For each tag, show the tag name and the number of photos associated with 
-- that tag. Rank the tags by the number of photos in descending order.
SELECT T.tag_name, COUNT(PT.photo_id) AS photo_count
FROM tags T
LEFT JOIN PHOTO_TAGS PT ON T.id = PT.tag_id
GROUP BY T.tag_name
ORDER BY photo_count DESC;

-- 7.List the usernames of users who have posted photos along with the count of 
-- photos they have posted. Rank them by the number of photos in descending order.
SELECT U.username, COUNT(P.id) AS photo_count
FROM USERS U
JOIN PHOTOS P ON U.id = P.user_id
GROUP BY U.username
ORDER BY photo_count DESC;

-- 8.Display the username of each user along with the creation date of their 
-- first posted photo and the creation date of their next posted photo.
WITH cte_user_first_next_photo AS (
    SELECT U.username, P.created_at AS first_photo_creation_date,
	LEAD(P.created_at) OVER (PARTITION BY P.user_id ORDER BY P.created_at) AS next_photo_creation_date
    FROM users AS U
	LEFT JOIN photos AS P ON U.id = P.user_id
)
SELECT username, first_photo_creation_date, next_photo_creation_date
FROM cte_user_first_next_photo;
    
-- 9.For each comment, show the comment text, the username of the commenter, 
-- and the comment text of the previous comment made on the same photo.
SELECT C.comment_text AS current_comment_text, U.username AS commenter_username,
LAG(C.comment_text) OVER (PARTITION BY C.photo_id ORDER BY C.id) AS previous_comment_text
FROM comments AS C
LEFT JOIN users AS U ON C.user_id = U.id
ORDER BY C.photo_id, C.id;

-- 10.Show the username of each user along with the number of photos they have posted and 
-- the number of photos posted by the user before them and after them, based on the creation date.
WITH UserPhotoCounts AS (
    SELECT U.id AS user_id, U.username, P.id AS photo_id, P.user_id AS photo_user_id,
	ROW_NUMBER() OVER (PARTITION BY P.user_id ORDER BY P.created_at) AS photo_rank
    FROM users U
    LEFT JOIN photos P ON U.id = P.user_id
),
UserPhotoCountsWithPrevNext AS (
    SELECT UP.*,
	LAG(UP.photo_id) OVER (PARTITION BY UP.user_id ORDER BY UP.photo_rank) AS prev_photo_id,
	LEAD(UP.photo_id) OVER (PARTITION BY UP.user_id ORDER BY UP.photo_rank) AS next_photo_id
    FROM UserPhotoCounts UP
)
SELECT U.username,
COUNT(DISTINCT P.id) AS user_photo_count,
COUNT(DISTINCT UPC.prev_photo_id) AS prev_user_photo_count,
COUNT(DISTINCT UPC.next_photo_id) AS next_user_photo_count
FROM users AS U
LEFT JOIN UserPhotoCountsWithPrevNext UPC ON U.id = UPC.user_id
LEFT JOIN photos AS P ON U.id = P.user_id
GROUP BY U.username ORDER BY U.username;

-- FINISH --