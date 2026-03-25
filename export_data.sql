SELECT id, COUNT(*) as cnt FROM `jadipintar-staging`.learning_journey_chapter GROUP BY id;

use `jadipintar-staging`

select id,name, email from users where email like '%nyiri%'

select count(*), min(createdat), max(createdat) from conversation_log cl

# monthly data
SELECT 
    DATE_FORMAT(cl.createdat, '%Y-%m') AS month,
    COUNT(*) AS total
FROM conversation_log cl
JOIN users u ON cl.userid = u.id
JOIN topic t ON t.id = cl.topicid
WHERE
    u.name LIKE 'demo-test%'
    #AND DATE_FORMAT(cl.createdat, '%Y-%m') like '2026%'
GROUP BY month
ORDER BY month;

# group by user & topic
SELECT  IFNULL(user, 'NA') AS user,  topic, COUNT(*) AS total
FROM (
  SELECT    u.name AS user, t.name AS topic
  FROM
    conversation_log cl
    JOIN users u ON cl.userid = u.id
    JOIN topic t ON t.id = cl.topicid
  WHERE
  	1=1
    #u.name like 'Siska Nurul' or u.name like 'Jihan Azhari'
    AND u.name like 'demo-test%'
    #t.name like '%'
    #AND cl.createdat >= NOW() - INTERVAL 7 DAY
    #cl.createdat >= '2025-09-01'
    #AND t.name='free'
    #AND u.joinReferralCode='SMAN3TAM'
) a
GROUP BY a.user, a.topic
#having total>=100
order by 1	#count(*) desc;

# group by day
SELECT  IFNULL(user, 'NA') AS user,  topic, COUNT(*) AS total
FROM (
  SELECT    cl.createdat
  FROM
    conversation_log cl
    JOIN users u ON cl.userid = u.id
    JOIN topic t ON t.id = cl.topicid
  WHERE
  	1=1
    #u.name like 'Siska Nurul' or u.name like 'Jihan Azhari'
    AND u.name like 'demo-test%'
    #t.name like '%'
    #AND cl.createdat >= NOW() - INTERVAL 7 DAY
    #cl.createdat >= '2025-09-01'
    #AND t.name='free'
    #AND u.joinReferralCode='SMAN3TAM'
) a
GROUP BY a.user, a.topic
#having total>=100
order by 1	#count(*) desc;

select id, userid, createdAt, attempt, response, userMessage, cl.* from conversation_log cl limit 3

#select cl.id, cl.userid, u.name Name, t.name 'Topic Name'
select u.name user, t.name topic, cl.id, cl.createdAt, attempt, response, userMessage
from conversation_log cl join users u on cl.userid=u.id join topic t on t.id=cl.topicid 
	#AND cl.createdat >= '2025-09-01' 
	AND ( t.name='freeX' or t.name='assessment_test' )
	#AND (u.name like 'Siska Nurul' or u.name like 'Jihan Azhari')	#'demo-test-100'
	#AND u.name like 'demo-test%'
	order by cl.id
	limit 100
	
