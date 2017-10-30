-- MLS Predictions Database Code 

CREATE TABLE Conference
(ConferenceID INT Identity(1, 1) primary key not null,
ConferenceName varchar(35) not null)

CREATE TABLE TEAM
(TeamID INT Identity(1, 1) primary key not null,
TeamName varchar(35) not null,
TeamAbbrv varchar(50) not null, 
ConferenceID INT foreign key references CONFERENCE(ConferenceID) not null)

CREATE TABLE GAME 
(GameID INT Identity(1, 1) primary key not null,
 HomeScore  INT,
 AwayScore INT,
 GameDate date)

 CREATE TABLE GAME_TEAM_HA 
 (GTHAID INT Identity(1, 1) primary key not null,
  GTHAName varchar(4) not null)


CREATE TABLE GAME_TEAM
(GameTeamID INT Identity(1, 1) primary key not null, 
 GameID INT foreign key references GAME(GameID) not null,
 TeamID INT foreign key references TEAM(TeamID) not null, 
 GTHAID INT foreign key references GAME_TEAM_HA(GTHAID) not null)


CREATE TABLE PREDICTION
(PredictionID INT Identity(1,1) primary key not null,
 GameID INT foreign key references GAME(GameID), 
 PredictionName varchar(35), 
 Result varchar(5) not null)

CREATE TABLE RESULT 
(ResultID INT Identity(1, 1) primary key not null, 
 ActualResult varchar(5) not null, 
 PredResult varchar(5) not null,
 PredictionID INT foreign key references PREDICTION(PredictionID) not null)


-- Creates a new game with game date 
GO

CREATE PROC NewGame 
@GameDate DATE,
@GameID INT OUTPUT
AS

BEGIN TRAN T1
    INSERT INTO GAME([GameDate])
    VALUES(@GameDate)
    
    SET @GameID = (SELECT SCOPE_IDENTITY())

IF @@ERROR<> 0 
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1

GO



-- Creates a new GAME_TEAM entry, as well as the proper GTHAID 
GO

Alter PROC NewGameTeam 
@TeamAbbrev varchar(35), 
@GTHAName varchar(35), 
@GameID int 

AS

DECLARE @GTHAID int 
DECLARE @TeamID int

SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamAbbrv like @TeamAbbrev) 
SET @GTHAID = (SELECT GTHAID FROM GAME_TEAM_HA WHERE GTHAName = @GTHAName)

IF(@TeamID is null)
    RAISERROR('Invalid Team or Home/Away Identifier', 12, 1)
    PRINT('Not working')
    RETURN

BEGIN TRAN T1

    INSERT INTO GAME_TEAM([GameID], [TeamID], [GTHAID])
    VALUES(@GameID, @TeamID, @GTHAID)

IF @@ERROR<> 0 
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1


GO


-- Adds a new game and prediction 


GO

ALTER PROC NewPredictionAndGame
@HomeTeamAbrv varchar(35),
@AwayTeamAbrv varchar(35),
@Result varchar(5),
@GameDate1 DATE

AS

DECLARE @HTID INT
DECLARE @ATID INT
DECLARE @GameID1 INT 
DECLARE @PredictionName varchar(35)




-- Sets the prediction name using home vs away team 
SET @PredictionName = @HomeTeamAbrv + 'vs'  + @AwayTeamAbrv
BEGIN 
    EXEC NewGame
    @GameDate = @GameDate1,
    @GameID = @GameID1 OUTPUT

    -- Adds the home team 
    EXEC NewGameTeam
    @TeamAbbrev = @HomeTeamAbrv,
    @GTHAName = 'Home',
    @GameID = @GameID1

    -- Adds the away team
    EXEC NewGameTeam
    @TeamAbbrev = @AwayTeamAbrv, 
    @GTHAName = 'Away',
    @GameID = @GameID1
END
BEGIN TRAN T1   


    INSERT INTO PREDICTION([GameID], [PredictionName], [Result])
    VALUES(@GameID1, @PredictionName, @Result)

IF @@ERROR <> 0
    ROLLBACK TRAN T1
ELSE    
    COMMIT TRAN T1

GO




-- Adds a result 
GO

CREATE PROC AddResult 
@HomeTeamAbv varchar(50),
@AwayTeamAbv varchar(50),
@Result varchar(5)

AS

DECLARE @PredictionName varchar(50)
DECLARE @PredictionID INT 
DECLARE @ResultTypeID INT
DECLARE @PredResult varchar(5)

SET @PredictionName = @HomeTeamAbv + 'vs' + @AwayTeamAbv
SET @PredictionID = (SELECT TOP 1 PredictionID FROM PREDICTION WHERE PredictionName = @PredictionName ORDER BY PredictionID DESC)
SET @PredResult = (SELECT PredResult FROM PREDICTION WHERE PredictionID = @PredictionID)

IF (@Result = @PredResult)
   SET @ResultTypeID = 1
ELSE
    SET @ResultTypeID = 2




SET @ResultTypeID = (SELECT ResultTypeID FROM RESULT_TYPE WHERE ResultTypeName = @ResultTypeName)


BEGIN TRAN T1
    INSERT INTO RESULT([PredictionID], [ResultTypeID])
    VALUES(@PredictionID, @ResultTypeID)

IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE    
    COMMIT TRAN T1
GO








-- Creates a team 
GO
CREATE PROC NewTeam 
@TeamName varchar(35), 
@TeamAbbrv varchar(35), 
@ConferenceName varchar(35)

AS

DECLARE @ConferenceID INT 
SET @ConferenceID = (SELECT ConferenceID FROM CONFERENCE WHERE ConferenceName = @ConferenceName)

BEGIN TRAN T1
    INSERT INTO TEAM([TeamName], [TeamAbbrv], [ConferenceID])
    VALUES(@TeamName, @TeamAbbrv, @ConferenceID)

IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE
    COMMIT TRAN T1


GO

-- Creates a result ResultType 
CREATE PROC NewResultType
@ResultTypeName varchar(35) 

AS

BEGIN TRAN T1

    INSERT INTO RESULT_TYPE([ResultTypeName])
    VALUES(@ResultTypeName)
IF @@ERROR <> 0
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1