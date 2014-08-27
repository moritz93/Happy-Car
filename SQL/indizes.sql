-- Index Autos
CREATE INDEX IDX_Autos ON Autos (KFZ_ID) WHERE Status = 'ARCHIVIERT';

-- Index Aufträge
CREATE INDEX IDX_Aufträge ON Aufträge (AID) WHERE Lieferdatum IS NOT NULL;

-- Index Werksaufträge
CREATE INDEX IDX_Werksaufträge ON Werksaufträge (WID, AID) WHERE Status = 'ARCHIVIERT';

-- Index bestellt
CREATE INDEX IDX_bestellt ON bestellt (BID) WHERE Status = 'ARCHIVIERT';

-- Index liefert
CREATE INDEX IDX_liefert ON liefert (KFZ_ID, MID, AID) WHERE Lieferdatum IS NOT NULL;
