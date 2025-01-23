SELECT 
    COUNT(CASE WHEN MONTHS_BETWEEN(Lifetime, SYSDATE) < 2 THEN 1 END) AS Tokens_Moins_De_2_Mois,
    COUNT(CASE WHEN MONTHS_BETWEEN(Lifetime, SYSDATE) < 1 THEN 1 END) AS Tokens_Moins_De_1_Mois
FROM 
    tokens
WHERE 
    Lifetime > SYSDATE;  -- Pour s'assurer que le token n'est pas déjà expiré


SELECT 
    COUNT(CASE WHEN MONTHS_BETWEEN(SYSDATE, TO_DATE('1970-01-01', 'YYYY-MM-DD') + (Lifetime / 86400)) > 1 THEN 1 END) AS Tokens_Moins_De_2_Mois,
    COUNT(CASE WHEN MONTHS_BETWEEN(SYSDATE, TO_DATE('1970-01-01', 'YYYY-MM-DD') + (Lifetime / 86400)) > 2 THEN 1 END) AS Tokens_Moins_De_1_Mois
FROM 
    tokens
WHERE 
    TO_DATE('1970-01-01', 'YYYY-MM-DD') + (Lifetime / 86400) > SYSDATE;  -- Tokens non expirés
