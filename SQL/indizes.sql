-- Index Autos
-- TODO
CREATE INDEX IDX_Autos ON Autos (KFZ_ID, Status);

-- Index Aufträge
-- TODO
CREATE INDEX IDX_Aufträge ON Aufträge (AID, Status);

-- Index Werksaufträge
-- TODO
CREATE INDEX IDX_Werksaufträge ON Werksaufträge (WID, AID, Status);

-- Index bestellt
-- TODO
CREATE INDEX IDX_bestellt ON bestellt (BID, Status);

-- Index liefert
-- TODO
CREATE INDEX IDX_liefert ON liefert (KFZ_ID, MID, AID, Status);
