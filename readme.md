# Générateur d’ID d’Idempotence avec UUIDv5

L'objectif est de générer des identifiants d’idempotence uniques et déterministes à partir de données métier, en utilisant UUID version 5 (UUIDv5) et des namespaces spécifiques par domaine fonctionnel (ICM, Compte, Client).

---

## Pourquoi UUIDv5 ?

- **Déterministe** : génère toujours le même UUID à partir des mêmes données d’entrée.
- **Idempotence** : idéal pour éviter les doublons dans les systèmes événementiels (Kafka, files de messages) ou API REST.
- **Namespaces** : segmentation claire par domaine pour éviter les collisions.

---

## Exemple nodejs

```bash
npm install uuid
node idempotence.js
```

## run 1
UUIDv5 ICM       : cd84638a-c8b5-5dde-8dd8-50f117b7e466
UUIDv5 Compte    : 17486325-c224-5efc-a706-bd2bde92d01b
UUIDv5 Client    : efb41922-7dbb-5600-be1c-0508dd5cb6a4
UUIDv4 (aléatoire): 75051924-6ece-4125-b6a0-6f473005ad9e

## run 2
UUIDv5 ICM       : cd84638a-c8b5-5dde-8dd8-50f117b7e466
UUIDv5 Compte    : 17486325-c224-5efc-a706-bd2bde92d01b
UUIDv5 Client    : efb41922-7dbb-5600-be1c-0508dd5cb6a4
UUIDv4 (aléatoire): db6af10a-fb0e-4090-98d5-5268eab509f4