
-- Q1 returns (name,born_in,father,mother)

SELECT A.name, A.born_in, A.father, A.mother 
FROM person A
WHERE A.born_in = (
    SELECT born_in 
    FROM person
    WHERE name = A.father
    ) 
AND A.born_in = (
    SELECT born_in
    FROM person
    WHERE name = A.mother
    )
ORDER BY A.name;

; 

-- Q2 returns (name)

SELECT name 
FROM (SELECT name, 
             accession, 
             LAG(accession, -1) OVER (ORDER BY accession) prevAccession 
      FROM monarch) 
      AS derivedTable

WHERE prevAccession < (
    SELECT dod 
    FROM person B 
    WHERE b.name = derivedTable.name
)
AND accession <> prevAccession
ORDER BY name
;

-- Q3 returns (house,name,accession)

SELECT A.house, 
       A.name, 
       A.accession
FROM monarch A
WHERE A.accession <= ALL (
                        SELECT accession
                        FROM monarch f
                        WHERE f.house = A.house
                        )
AND house IS NOT NULL
;

-- Q4 returns (name,role,start_date)
SELECT person.name,
    CASE
        WHEN accession IS NULL AND entry IS NOT NULL 
        THEN 'Prime Minister'

        WHEN entry IS NULL AND accession IS NOT NULL AND house IS NULL 
        THEN 'Lord Protector'

        WHEN entry IS NULL AND house IS NOT NULL 
        THEN 'Monarch'

        ELSE 'None'
    END AS role,
    CASE
        WHEN accession IS NULL 
        THEN entry

        WHEN entry IS NULL 
        THEN accession

        ELSE NULL
    END AS start_date

FROM person LEFT JOIN monarch
            ON person.name = monarch.name
            LEFT JOIN prime_minister 
            ON person.name = prime_minister.name

ORDER BY person.name, start_date
;

-- Q5 returns (first_name,popularity)

SELECT first_name, 
       COUNT(*) AS popularity

FROM (SELECT 
        CASE POSITION(' ' IN name)
            WHEN 0 
            THEN name 
            ELSE SUBSTRING(name, 1, POSITION(' ' IN name) - 1) 
        END AS first_name
      FROM person) 
      AS derivedTable

GROUP BY first_name
HAVING COUNT(*) > 1
ORDER BY popularity DESC, first_name ASC        

;

-- Q6 returns (party,eighteenth,nineteenth,twentieth,twentyfirst)

SELECT party,
    COUNT (CASE WHEN entry >= '1700-01-01' AND entry < '1800-01-01' THEN party END) AS eighteenth,
    COUNT (CASE WHEN entry >= '1800-01-01' AND entry < '1900-01-01' THEN party END) AS nineteenth,
    COUNT (CASE WHEN entry >= '1900-01-01' AND entry < '2000-01-01' THEN party END) AS twentieth,
    COUNT (CASE WHEN entry >= '2000-01-01' AND entry < '2100-01-01' THEN party END) AS twentyfirst
FROM prime_minister
GROUP BY party
ORDER BY party
; 

-- Q7 returns (mother,child,born)
SELECT derivedTable.name as mother, 
       B.name as child, 
       CASE 
            WHEN B.dob IS NULL 
            THEN NULL 
            ELSE RANK () OVER (PARTITION BY mother ORDER BY B.dob) 
       END AS born
FROM (SELECT name
      FROM person 
      WHERE gender = 'F') 
      AS derivedTable
      LEFT JOIN Person B
      ON B.mother = derivedTable.name
ORDER BY mother, born, child
;

-- Q8 returns (monarch,prime_minister)

SELECT DISTINCT derivedTable.name as monarch, 
                primeTable.name as prime_minister
FROM (SELECT name, 
             accession, 
             LAG(accession, -1) OVER (ORDER BY accession) endDate
      FROM monarch) 
      AS derivedTable

      INNER JOIN (SELECT name, 
                         entry, 
                         LAG(entry, -1) OVER (ORDER BY entry) endDate 
                  FROM prime_minister) 
                  AS primeTable
      ON (derivedTable.accession < primeTable.entry AND primeTable.entry < derivedTable.endDate) 
      OR (derivedTable.accession < primeTable.endDate AND primeTable.endDate < derivedTable.endDate) 
      OR (primeTable.entry < derivedTable.accession AND derivedTable.endDate < primeTable.endDate)
      OR (derivedTable.endDate IS NULL AND primeTable.entry > derivedTable.accession)
      OR (derivedTable.endDate IS NULL AND primeTable.endDate > derivedTable.accession) 
ORDER BY monarch, prime_minister
;

