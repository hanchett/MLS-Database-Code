-- Group Code 
-- Order
-- Ryan Hanchett - Lines 7 - 362
-- Sarah Park - Lines 366 - 553
-- Kimiko Farmer - Lines 556 - 900
-- Mason Shigenaka - Lines 906 - 1197


------------------------------------ Ryan Hanchett -------------------------------------------
-- Stored Procedures:


-- Creates random contract clauses for player contracts 
GO
CREATE PROC [dbo].[clauseContractSynth]
@Run INT

AS

DECLARE @ContractID1 INT
DECLARE @TeamID1 INT
DECLARE @BegDate DATE
DECLARE @Fname1 varchar(35)
DECLARE @Lname1 varchar(35)
DECLARE @DOB2 DATE
DECLARE @PlayerID1 INT
DECLARE @ClauseName1 varchar(35)

-- Rand vars
DECLARE @ContractedPlayers INT
DECLARE @NumClause INT

DECLARE @PlayerRand INT
DECLARE @ClauseID INT
DECLARE @ContractID INT
-- Limits this to only players with current contracts 
SET @ContractedPlayers = (SELECT TOP 1 PlayerID FROM CONTRACT c
						  WHERE c.EndDate is null
				          ORDER BY PlayerID DESC)

SET @NumClause = (SELECT COUNT(*) FROM CLAUSE)


WHILE @Run > 0
	BEGIN
		SET @PlayerRand = (SELECT CAST(RAND() * @ContractedPlayers AS INT))
		SET @ClauseID = (SELECT CAST(RAND() * @NumClause AS INT))
		SET @ContractID = (
				(CASE
					WHEN (@PlayerRand = 0) 
						THEN (SELECT TOP 1 PlayerID FROM CONTRACT)
					WHEN (@PlayerRand > @ContractedPlayers) 
						THEN @ContractedPlayers
					ELSE @PlayerRand
					END))

		SET @ClauseID = (
			CASE
				WHEN (@ClauseID = 0)
					THEN 1
				WHEN (@ClauseID > @NumClause)
					THEN @NumClause
				ELSE @ClauseID
				END)

		SET @ClauseName1 = (SELECT ClauseName FROM CLAUSE WHERE ClauseID = @ClauseID)

		SET @PlayerID1 = @ContractID
		
		SET @Fname1 = (SELECT p.PersonFname FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID1)
		SET @Lname1 = (SELECT p.PersonLname FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID1)
		SET @DOB2 = (SELECT p.PersonDOB FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID1)
	

		SET @BegDate = (SELECT GETDATE())
	

		EXEC [uspAddContractClause]
		@Start = @BegDate,
		@ClauseName = @ClauseName1,
		@ContractDate = @BegDate,
		@Fname = @Fname1, 
		@Lname = @Lname1, 
		@PersonDOB = @DOB2

		SET @Run = @Run - 1
	END
GO


-- Creates a new random player transaction between teams, creating a new contract at the same time ----------
GO
CREATE PROC [dbo].[newPlayerContractTranSynthetic]
@Run INT 
AS

-- All the params needed to execute the transaction 
DECLARE @Fname1 varchar(35)
DECLARE @Lname1 varchar(35)
DECLARE @DOB2 date
DECLARE @TeamName varchar(35)
DECLARE @BeginDate1 date 
DECLARE @Salary1 numeric(10, 2)
DECLARE @TransactionTypeName1 varchar(35)


-- Random variables & IDs to be used to grab information 
DECLARE @PlayerRand INT
DECLARE @TeamRand INT
DECLARE @PlayerID2 INT 
DECLARE @TeamID2 INT
DECLARE @NewContractID INT
DECLARE @TransactionTypeID INT

-- Random number limiters 
DECLARE @NumPlayers INT
DECLARE @NumTeam INT
DECLARE @NumTransactionTypes INT
DECLARE @NumTransaction VARCHAR(30) = 'Transaction Number: ' + CAST((SELECT COUNT(*) + 1 FROM [TRANSACTION]) AS VARCHAR(20))

SET @NumPlayers = (SELECT TOP 1 PlayerID FROM PLAYER ORDER BY PlayerID DESC)
SET @NumTeam = (SELECT TOP 1 TeamID FROM TEAM ORDER BY TeamID DESC)
SET @NumTransactionTypes = (SELECT TOP 1 TransactionTypeID FROM TRANSACTION_TYPE ORDER BY TransactionTypeID DESC)

WHILE @Run > 0
    BEGIN 
        SET @PlayerRand = (SELECT CAST(RAND() * @NumPlayers AS INT))
        SET @TeamRand = (SELECT CAST(RAND() * @NumTeam AS INT))
		SET @TransactionTypeID = (SELECT CAST(RAND() * @NumTransactionTypes AS INT))

        -- Sets the IDs for Player and Team based on the random function, dealing with edge cases for the random #
        SET @PlayerID2 = (
            (CASE
                WHEN (@PlayerRand = 0) 
                    THEN 12
                ELSE
                    @PlayerRand
				END))
        SET @TeamID2 = (
            (CASE    
                WHEN (@TeamRand = 0)
                    THEN 4
                ELSE 
                    @TeamRand
				END))
		SET @TransactionTypeName1 = (
			(CASE
				WHEN @TransactionTypeID = 0
					THEN 1
				ELSE
					@TransactionTypeID
				END)) 
		SET @TransactionTypeName1 = (SELECT TransactionTypeName FROM TRANSACTION_TYPE WHERE TransactionTypeID = @TransactionTypeName1)
        -- Sets all the info needed for the transaction using the randomly generated IDs
        SET @BeginDate1 = (SELECT GETDATE() - CAST(RAND() AS INT) * 7300)
        SET @Fname1 = (SELECT p.PersonFname FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID2)
        SET @Lname1 = (SELECT p.PersonLname FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID2)
        SET @DOB2 = (SELECT p.PersonDOB FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID2)
        SET @TeamName = (SELECT TeamName FROM TEAM WHERE TeamID = @TeamID2)
        --Gets a salary above league minimum that's somewhere between minimum and a 1,600,000.
        SET @Salary1 = CAST(RAND() * 1000000 AS INT) + 10000

        EXEC newContract
        @Fname = @Fname1,
        @Lname = @Lname1,
		@DOB1 = @DOB2,
        @TeamName1 = @TeamName,
        @Salary = @Salary1,
        @BeginDate = @BeginDate1,
        @EndDate = null,
		@ContractID = @NewContractID OUTPUT

		
		
		EXEC newTransaction
		@TransactionTypeName = @TransactionTypeName1,
		@TransactionName = @NumTransaction,
		@TransactionDate = @BeginDate1,
		@ContractID = @NewContractID, 
		@ContractBegDate = @BeginDate1


        SET @Run = @Run - 1
    END 
GO


-- Check Constraints:
-- Teams must be within salary cap
GO
CREATE FUNCTION signingFitsSalaryCap() 
RETURNS INT
AS 
BEGIN
DECLARE @RET INT = 0
IF EXISTS (SELECT SUM((CASE 
                WHEN c.Salary > 480625
                    THEN 480625
                ELSE c.Salary
            END)), t.TeamName FROM CONTRACT c 
           JOIN TEAM t ON t.TeamID = c.TeamID
		   WHERE c.EndDate is null 
           GROUP BY t.TeamName
           HAVING SUM(c.Salary) > 3845000)
    SET @RET =  1
RETURN @RET
END
GO

ALTER TABLE CONTRACT 
ADD CONSTRAINT NoBreakingSalaryCap
CHECK(dbo.signingFitsSalaryCap() = 0)

-- Teams can only have 3 “DP”s (Players of 400Kish on salary)
GO
ALTER FUNCTION onlyThreeDPs()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT COUNT(*), t.TeamID, c.ContractID FROM CONTRACT c
         JOIN TEAM t ON t.TeamID = c.TeamID
         WHERE c.Salary >= 480625
         AND c.EndDate is null
         GROUP BY t.TeamID, c.ContractID
         HAVING COUNT(*) > 3)
         SET @RET = 1
RETURN @RET
END
GO

ALTER TABLE CONTRACT 
ADD CONSTRAINT OnlyThreeDP
CHECK(dbo.onlyThreeDPs() = 0)



-- Views: 
-- Standings (Split by conference) of each team, including number of wins, ties & losses with goals for and goals against 
GO
CREATE VIEW Standings
AS
(SELECT t.TeamName, c.ConferenceName, (p.NumPoints + q.NumPoints) AS Points
FROM TEAM t
LEFT JOIN 
(SELECT t.TeamName, COUNT(*) * 3 as NumPoints FROM GAME g
JOIN GAME_TEAM gt on g.GameID = gt.GameID
JOIN TEAM t ON t.TeamID = gt.TeamID
JOIN GAME_TEAM_HA gth ON gth.GameTeamHAID = gt.GameTeamHAID
WHERE (gth.GameTeamHAName = 'Home' AND g.HomeScore > AwayScore)
OR (gth.GameTeamHAName = 'Away' AND g.AwayScore >  g.HomeScore)
GROUP BY t.TeamName) p
ON t.TeamName = p.TeamName
LEFT JOIN 
(SELECT t.TeamName, COUNT(*) as NumPoints FROM GAME g
JOIN GAME_TEAM gt on g.GameID = gt.GameID
JOIN TEAM t ON t.TeamID = gt.TeamID
JOIN GAME_TEAM_HA gth ON gth.GameTeamHAID = gt.GameTeamHAID
WHERE  g.HomeScore = g.AwayScore
GROUP BY t.TeamName) q
ON 
t.TeamName = q.TeamName
JOIN TEAM_CONFERENCE tc ON t.TeamID = tc.TeamID
JOIN CONFERENCE c ON c.ConferenceID = tc.ConferenceID
GROUP BY T.TeamName, q.NumPoints, p.NumPoints, c.ConferenceName)
GO

SELECT * FROM Standings 

-- Only shows Western Conference Teams 
GO
CREATE VIEW WesternConferenceStandings
AS 
SELECT * FROM Standings
WHERE ConferenceName = 'Western Conference'
GO

SELECT * FROM WesternConferenceStandings
ORDER BY POINTS DESC

-- Only shows Eastern Conference Standings 
GO
CREATE VIEW EasternConferenceStandings
AS 
SELECT * FROM Standings
WHERE ConferenceName = 'Eastern Conference'
GO



-- All players currently under contract for each team, ordered by salary, maybe case statement to break up into salary categories (DP, Senior Minimum, Rookie Minimum, etc.) 
GO
CREATE VIEW TeamRosters 
AS
SELECT t.TeamName, per.PersonFname, per.PersonLname, c.Salary, 
(CASE 
    WHEN c.Salary >= 480625
        THEN 'DP'
    WHEN c.Salary < 480625 AND c.Salary >= 80000
        THEN 'Normal Player'
    WHEN c.Salary > 65000 AND c.Salary < 80000
        THEN 'Senior Player'
    ELSE 'Rookie' 
    END) AS 'Salary Type' FROM TEAM t 
JOIN CONTRACT c ON c.TeamID = t.TeamID 
JOIN PLAYER p ON p.PlayerID = c.PlayerID
JOIN PERSON per ON per.PersonID = p.PersonID
WHERE c.EndDate is NULL
GROUP BY t.teamName, per.PersonFname, per.PersonLname, c.Salary,
(CASE 
    WHEN c.Salary >= 480625
        THEN 'DP'
    WHEN c.Salary < 480625 AND c.Salary >= 80000
        THEN 'Normal Player'
    WHEN c.Salary > 65000 AND c.Salary < 80000
        THEN 'Senior Player'
    ELSE 'Rookie' 
END)
GO

--Grabs the Seattle Sounder's Roster 
SELECT * FROM TeamRosters
WHERE TeamName like '%Seattle%'

-- Computed Columns: 
-- Amount of money a team is spending on salaries 
GO
CREATE FUNCTION TeamSalary(@TeamID INT)
RETURNS INT 
AS 
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT 
           SUM((CASE 
                WHEN c.Salary > 480625
                    THEN 480625
                ELSE c.Salary
            END)) FROM CONTRACT c 
            JOIN TEAM t ON t.TeamID = c.TeamID 
            WHERE c.EndDate is null
            AND t.TeamID = @TeamID) 
RETURN @RET
END
GO

ALTER TABLE TEAM 
ADD TotalSalary as (dbo.TeamSalary(TeamID))


-- A player's total historical earnings 
GO
CREATE FUNCTION PlayerCareerEarnings(@PlayerID INT)
RETURNS INT 
AS
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT SUM(c.Salary) FROM CONTRACT c 
            WHERE c.PlayerID = @PlayerID)
RETURN @RET
END
GO
ALTER TABLE PLAYER 
ADD CareerEarnings AS (dbo.PlayerCareerEarnings(PlayerID))



------------------------------------ Sarah Park -------------------------------------------

-- Stored Procedure
CREATE PROCEDURE uspAddTeamWithGame
@TeamName1 varchar(35),
@TeamName2 varchar(35),
@HomeScore INT,
@AwayScore INT,
@GameDate DATE,
@GameTypeName varchar(35)
AS
DECLARE @TeamID1 INT
DECLARE @TeamID2 INT
DECLARE @Team1HA INT 
DECLARE @Team2HA INT
DECLARE @GameTypeID INT
DECLARE @GameID INT

SET @TeamID1 = (SELECT TeamID FROM TEAM
				WHERE TeamName = @TeamName1)
SET @TeamID2 = (SELECT TeamID FROM TEAM
				WHERE TeamName = @TeamName2)
SET @Team1HA = (SELECT(CAST ((SELECT RAND())*(2) + 1 AS INT)))
SET @Team2HA = 3 - @Team1HA
SET @GameTypeID = (SELECT GameTypeID FROM GAME_TYPE
				WHERE GameTypeName = @GameTypeName)
BEGIN TRAN T1
	IF @GameID IS NULL
		BEGIN
			INSERT INTO GAME(HomeScore, AwayScore, GameDate, GameTypeID)
			VALUES(@HomeScore, @AwayScore, @GameDate, @GameTypeID)
			SET @GameID = (SELECT SCOPE_IDENTITY())
		END
	INSERT INTO GAME_TEAM(GameID, TeamID, GameTeamHAID)
	VALUES(@GameID, @TeamID1, @Team1HA)
	INSERT INTO GAME_TEAM(GameID, TeamID, GameTeamHAID)
	VALUES(@GameID, @TeamID2, @Team2HA)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1

CREATE PROCEDURE uspSyntheticGameWithTeams
@Run INT
AS
-- Used to generate a random PK
DECLARE @Rand INT

-- Grab to get random row from that table
DECLARE @Team1 varchar(35)
DECLARE @Team2 varchar(35)
DECLARE @GameTypeName1 varchar(35)
DECLARE @Home INT
DECLARE @Away INT
DECLARE @Date DATE

WHILE @RUN > 0
BEGIN

-- Generate random score values
SET @Home = (SELECT(CAST ((SELECT RAND())*(10) AS INT)))
SET @Away = (SELECT(CAST ((SELECT RAND())*(10) AS INT)))

-- Generate random date within the past 5 years
SET @Date = (SELECT GETDATE() - CAST(RAND() * 365 AS INT))

-- Grab a random TEAM
SET @Team1 = (SELECT TeamName FROM TEAM WHERE TeamID = (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM TEAM) + 1 AS INT))))
SET @Team2 = (SELECT TeamName FROM TEAM WHERE TeamID = (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM TEAM) + 1 AS INT))))

-- Grab a random GAME_TYPE
SET @GameTypeName1 = (SELECT GameTypeName FROM GAME_TYPE WHERE GameTypeID =  (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM GAME_TYPE) + 1 AS INT))))

	EXEC uspAddTeamWithGame
		@TeamName1 = @Team1,
		@TeamName2 = @Team2,
		@HomeScore = @Home,
		@AwayScore = @Away,
		@GameDate = @Date,
		@GameTypeName = @GameTypeName1
	SET @RUN = @RUN - 1
END


CREATE PROCEDURE uspAddGameType
@GameTypeName varchar(35)
AS
BEGIN TRAN T1
	INSERT INTO GAME_TYPE(GameTypeName)
	VALUES(@GameTypeName)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1


CREATE PROCEDURE uspGetTeamID
@TeamName varchar(35),
@TeamID INT OUTPUT
AS
SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamName = @TeamName)


-- Check Constraint
CREATE FUNCTION fnNoNegativeScores()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT * FROM GAME
		WHERE HomeScore < 0 OR AwayScore < 0)
SET @RET = 1
RETURN @RET
END

ALTER TABLE GAME_TEAM
ADD CONSTRAINT ck_NoNegativeScores
CHECK (dbo.fnNoNegativeScores() = 0)


CREATE FUNCTION fnMaxTeamOwners()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT count(o.OwnerID) FROM TEAM t
	JOIN TEAM_OWNER tow on t.TeamID = tow.TeamID
	JOIN [OWNER] o on tow.OwnerID = o.OwnerID
	GROUP BY o.OwnerID
	HAVING count(o.OwnerID) > 3)
SET @RET = 1
RETURN @RET
END

ALTER TABLE TEAM_OWNER
ADD CONSTRAINT ck_NoMoreThan3TeamsPerOwner
CHECK (dbo.fnMaxTeamOwners() = 0)

-- Computed Column
CREATE FUNCTION fnPlayersManaged(@AgentID INT)
RETURNS INT
AS 
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT count(agent.AgentID) FROM PLAYER player
	JOIN PERSON per on player.PersonID = per.PersonID
	JOIN PLAYER_AGENT pa on player.PlayerID = pa.PlayerID
	JOIN AGENT agent on pa.AgentID = agent.AgentID
	WHERE agent.AgentID = @AgentID
	GROUP BY agent.AgentName)
SET @RET = (CASE WHEN (@RET IS NULL) THEN 0 ELSE @RET END)
RETURN @RET
END

ALTER TABLE AGENT
ADD PlayersManaged
AS (dbo.fnPlayersManaged(AgentID))


CREATE FUNCTION fnCountGamesPlayedByTeam(@TeamID INT)
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT count(t.TeamID) FROM TEAM t
	JOIN GAME_TEAM gt on t.TeamID = gt.TeamID
	WHERE t.TeamID = @TeamID
	GROUP BY t.TeamID)
RETURN @RET
END

ALTER TABLE TEAM
ADD GamesPlayed
AS (dbo.fnCountGamesPlayedByTeam(TeamID))

-- Views
CREATE VIEW [Contracted Player List] AS 
(SELECT PersonFname, PersonLname, TeamName, c.BeginDate FROM PLAYER p
JOIN [CONTRACT] c on p.PlayerID = c.PlayerID
JOIN TEAM t on c.TeamID = t.TeamID
JOIN PERSON per on p.PersonID = per.PersonID
WHERE (c.EndDate IS NULL))

CREATE VIEW [Team Owner List] AS
(SELECT PersonFname, PersonLname, TeamName FROM [OWNER] o
JOIN PERSON p on o.PersonID = p.PersonID
JOIN TEAM_OWNER tow on o.OwnerID = tow.OwnerID
JOIN TEAM t on tow.TeamID = t.TeamID)



------------------------------------ Kimiko Farmer -------------------------------------------

--Synthetic Transaction

ALTER PROCEDURE [dbo].[uspSyntheticTeamEmployee]
@Run INT
AS
/* Declare necessary variables to run procedure */
DECLARE @Fname varchar(35)
DECLARE @Lname varchar(35)
DECLARE @DOB date

DECLARE @TeamName varchar(35)
DECLARE @EmployeeTypeName varchar(35)

/* Calculate size of tables to use to select random Team and Employee */
DECLARE @EmployeeLength INT
SET @EmployeeLength = (SELECT COUNT(*) FROM EMPLOYEE)
DECLARE @TeamLength INT
SET @TeamLength = (SELECT COUNT(*) FROM TEAM)
DECLARE @EmployeeTypeLength INT
SET @EmployeeTypeLength = (SELECT COUNT(*) FROM EMPLOYEE_TYPE)

DECLARE @RandomEmployee INT
DECLARE @RandomTeam INT
DECLARE @RandomEmployeeType INT

DECLARE @EmployeeID INT
DECLARE @PersonID INT
DECLARE @TeamID INT
DECLARE @EmployeeTypeID INT
DECLARE @Char CHAR

/* Randomly pick an Employee and Team */
WHILE @Run > 0
BEGIN
	SET @RandomEmployee = (SELECT CAST(RAND() * @EmployeeLength AS INT))
	SET @EmployeeID = (CASE
				WHEN @RandomEmployee = 0
				THEN 1
				ELSE @RandomEmployee
				END
			   )
	IF @EmployeeID IS NULL
		BEGIN
		RAISERROR ('EmployeeID cannot be NULL; please check all input values', 12,1)
		END

	SET @RandomTeam = (SELECT CAST(RAND() * @TeamLength AS INT))
	SET @TeamID = (CASE
				WHEN @RandomTeam = 0 
				THEN 1
				ELSE @RandomTeam
				END
			   )
	IF @TeamID IS NULL
		BEGIN
		RAISERROR ('TeamID cannot be NULL; please check all input values', 12,1)
		END;
	SET @EmployeeTypeID = (SELECT EmployeeTypeID FROM EMPLOYEE WHERE EmployeeID = @EmployeeID)
	IF @EmployeeTypeID IS NULL
		BEGIN
		RAISERROR ('EmployeeTypeID cannot be NULL; please check all input values', 12,1)
	END;

	/* Find the values for the necessary variables from the random Employee and Team */
	SET @PersonID = (SELECT PersonID FROM EMPLOYEE WHERE EmployeeID = @EmployeeID)
	SET @Fname = (SELECT PersonFname FROM PERSON WHERE PersonID = @PersonID)
	SET @Lname = (SELECT PersonLname FROM PERSON WHERE PersonID = @PersonID)
	SET @DOB = (SELECT PersonDOB FROM PERSON WHERE PersonID = @PersonID)
	SET @TeamName = (SELECT TeamName FROM TEAM WHERE TeamID = @TeamID)
	IF @TeamName IS NULL
		BEGIN
		RAISERROR ('TeamName cannot be NULL; please check all input values', 12,1)
		END;

	SET @EmployeeTypeName = (SELECT EmployeeTypeName FROM EMPLOYEE_TYPE WHERE EmployeeTypeID = @EmployeeTypeID)

	/*Assign the employee to the team*/
	EXEC uspAssignEmployeeTeam
	@Fname1 = @Fname,
	@Lname1 = @Lname,
	@DOB1 = @DOB,
	@TeamName1 = @TeamName,
	@EmployeeTypeName1 = @EmployeeTypeName

	SET @Run = @Run - 1
END



--Stored Procedure that is used in Synthetic Transaction

ALTER PROCEDURE [dbo].[getEmployeeIDForTeamEmployee]
@Fname varchar(35),
@Lname varchar(35),
@DOB date,
@EmployeeTypeName varchar(35),
@EmployeeID INT OUTPUT
AS
DECLARE @EmployeeTypeID INT 
DECLARE @PersonID INT
BEGIN
	/* Have to retreieve PersonID and EmployeeTypeID before finding EmployeeID */
	SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @Fname AND PersonLname = @Lname AND PersonDOB = @DOB)
	SET @EmployeeTypeID = (SELECT EmployeeTypeID FROM EMPLOYEE_TYPE WHERE EmployeeTypeName = @EmployeeTypeName)

	SET @EmployeeID = (SELECT TOP 1 EmployeeID FROM EMPLOYEE WHERE PersonID = @PersonID AND EmployeeTypeID = @EmployeeTypeID)
END



--Synthetic Transaction

ALTER PROCEDURE [dbo].[uspSyntheticContractClause]
@Run INT
AS
/* Declare necessary variables to run procedure */
DECLARE @Start1 DATE
DECLARE @ClauseName1 varchar(35)
DECLARE @ContractDate1 Date
DECLARE @TeamName1 varchar(35)
DECLARE @Fname1 varchar(35)
DECLARE @Lname1 varchar(35)
DECLARE @DOB1 Date

/* Calculate size of Contract and Clause table to choose a random one later*/
DECLARE @ContractLength INT
SET @ContractLength = (SELECT COUNT(*) FROM [CONTRACT])
DECLARE @ClauseLength INT
SET @ClauseLength = (SELECT COUNT(*) FROM CLAUSE)
DECLARE @RandomContract INT
DECLARE @RandomClause INT

DECLARE @ContractID INT
DECLARE @ClauseID INT
DECLARE @TeamID INT 
DECLARE @PlayerID INT
DECLARE @PlayerTypeID INT
DECLARE @PersonID INT

/* Randomly pick a Contract and Clause */
WHILE @Run > 0
BEGIN
	SET @RandomContract = (SELECT CAST(RAND() * @ContractLength AS INT))
	SET @ContractID = (CASE
				WHEN @RandomContract = 0
				THEN 1
				ELSE @RandomContract
				END
				)
	IF @ContractID IS NULL
		BEGIN
		RAISERROR ('ContractID cannot be NULL; please check all input values', 12,1)
	END

	SET @RandomClause = (SELECT CAST(RAND() * @ClauseLength AS INT))
	SET @ClauseID = (CASE
				WHEN @RandomClause = 0
				THEN 1
				ELSE @RandomClause
				END
			   )
	IF @ClauseID IS NULL
		BEGIN
		RAISERROR ('TeamID cannot be NULL; please check all input values', 12,1)
		END;

	/* Find the values for the necessary variables from the random Contract and Clause */
	SET @Start1 = (SELECT GETDATE())

	SET @TeamID = (SELECT TeamID FROM [CONTRACT] WHERE ContractID = @ContractID)
	SET @TeamName1 = (SELECT TeamName FROM TEAM WHERE TeamID = @TeamID)
	
	SET @PlayerID = (SELECT PlayerID FROM [CONTRACT] WHERE ContractID = @ContractID)

	SET @PersonID = (SELECT PersonID FROM PLAYER WHERE PlayerID = @PlayerID)
	SET @Fname1 = (SELECT PersonFname FROM PERSON WHERE PersonID = @PersonID)
	SET @Lname1 = (SELECT PersonLname FROM PERSON WHERE PersonID = @PersonID)
	SET @DOB1 = (SELECT PersonDOB FROM PERSON WHERE PersonID = @PersonID)
	
	SET @ClauseName1 = (SELECT ClauseName FROM CLAUSE WHERE ClauseID = @ClauseID)

	SET @ContractDate1 = (SELECT BeginDate FROM [CONTRACT] WHERE ContractID = @ContractID)

	/*Execute adding the clause to the contract */
	exec uspAddContractClause
	@Start = @Start1,
	@ClauseName = @ClauseName1,
	@ContractDate = @ContractDate1,
	@Fname = @Fname1,
	@Lname = @Lname1,
	@PersonDOB = @DOB1

	SET @Run = @Run - 1
END



--Stored Procedure that is used in Synthetic Transaction

ALTER PROCEDURE [dbo].[uspAddContractClause]
@Start DATE,
@ClauseName varchar(35),
@ContractDate Date,
@Fname varchar(35),
@Lname varchar(35),
@PersonDOB Date
AS
DECLARE @ContractID INT
DECLARE @ClauseID INT
DECLARE @PersonID INT
DECLARE @PlayerID1 INT
DECLARE @TeamID INT

/*Grab playerID*/
exec getPlayerID 
@PlayerFname = @Fname,
@PlayerLname = @Lname,
@DOB = @PersonDOB,
@PlayerID = @PlayerID1 OUT

SET @ContractID = (SELECT Top 1 ContractID FROM [CONTRACT] WHERE PlayerID = @PlayerID1 )

SET @ClauseID = (SELECT ClauseID FROM CLAUSE WHERE ClauseName = @ClauseName)

/*Insert into Contract_Clause the Contract and Clause*/
BEGIN TRAN T1
	INSERT INTO CONTRACT_CLAUSE(ContractClauseStartDate, ContractID, ClauseID)
	VALUES(@Start, @ContractID, @ClauseID)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1



--Check Constraint 1

CREATE FUNCTION fnNoContractEndDateBeforeStartDate()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT * FROM [CONTRACT]
		WHERE EndDate < BeginDate)
SET @RET = 1
RETURN @RET
END

ALTER TABLE [CONTRACT]
ADD CONSTRAINT ck_NoContractEndDateBeforeStartDate
CHECK (dbo.fnNoContractEndDateBeforeStartDate() = 0)



--Check Constraint 2

CREATE FUNCTION fnOperationsOneTeam()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT COUNT(e.EmployeeID) FROM EMPLOYEE e
		JOIN TEAM_EMPLOYEE te ON e.EmployeeID = te.EmployeeID
		JOIN TEAM t ON te.TeamID = t.TeamID
		JOIN EMPLOYEE_TYPE et ON e.EmployeeTypeID = et.EmployeeTypeID
		WHERE et.EmployeeTypeName = 'Operations'
		GROUP BY t.TeamName
		HAVING COUNT(*) > 1)
SET @RET = 1
RETURN @RET
END

ALTER TABLE [TEAM_EMPLOYEE]
ADD CONSTRAINT ck_OperationsOneTeam
CHECK (dbo.fnOperationsOneTeam() = 0)



--Computed Column 1

CREATE FUNCTION fnTotalGamesStadium(@StadiumID INT)
RETURNS INT
AS 
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT COUNT(g.GameID) FROM GAME g
	JOIN GAME_TEAM gt on g.GameID = gt.GameID
	JOIN TEAM t on gt.TeamID = t.TeamID
	JOIN STADIUM s on t.StadiumID = s.StadiumID
	WHERE s.StadiumID = @StadiumID)
SET @RET = (CASE WHEN (@RET IS NULL) THEN 0 ELSE @RET END)
RETURN @RET
END

ALTER TABLE STADIUM
ADD TotalGamesPlayed
AS (dbo.fnTotalGamesStadium(StadiumID))


--Computed Column 2

CREATE FUNCTION fnTotalNumberEmployees(@TeamID INT)
RETURNS INT
AS 
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT COUNT(e.EmployeeID) FROM EMPLOYEE e
	JOIN TEAM_EMPLOYEE te ON e.EmployeeID = te.EmployeeID
	JOIN TEAM t ON te.TeamID = t.TeamID
	WHERE t.TeamID = @TeamID)
SET @RET = (CASE WHEN (@RET IS NULL) THEN 0 ELSE @RET END)
RETURN @RET
END

ALTER TABLE TEAM
ADD NumberOfEmployees
AS (dbo.fnTotalNumberEmployees(TeamID))



--View 1

CREATE VIEW [Players Currently Managed By An Agent] AS 
(SELECT a.AgentName, per.PersonFname, per.PersonLname, t.TeamName FROM AGENT a
JOIN PLAYER_AGENT pa on a.AgentID = a.AgentID
JOIN PLAYER p on pa.PlayerID = p.PlayerID
JOIN PERSON per on p.PersonID = per.PersonID
JOIN EMPLOYEE e on per.PersonID = e.EmployeeID
JOIN TEAM_EMPLOYEE te on e.EmployeeID = te.EmployeeID
JOIN TEAM t on te.TeamID = t.TeamID
WHERE (pa.EndDate IS NULL))



--View 2

CREATE VIEW [Number of MLS Cup Games a Team Has Played] AS 
(SELECT t.TeamName as Team_Name , COUNT(g.GameID) as Number_of_Games FROM TEAM t
JOIN GAME_TEAM gt ON t.TeamID = gt.TeamID
JOIN GAME g ON gt.GameID = g.GameID
JOIN GAME_TYPE gty ON g.GameTypeID = gty.GameTypeID
WHERE gty.GameTypeName = 'MLS Cup'
GROUP BY t.TeamName)



------------------------------------ Mason Shigenaka -------------------------------------------
USE MLS
GO

--Stored Procedure to create a new player. If person does not exist in player table, the procedure will add in the new player into the person table then the player table
ALTER PROC [dbo].[uspCreateNewPlayer]
@PlayerFname varchar(35),
@PlayerLname varchar(35),
@PlayerDOB Date,
@PlayerEmail varchar(35),
@PlayerType varchar(35)
AS
DECLARE @PersonID INT
DECLARE @PlayerTypeID INT
SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @PlayerFname AND PersonLname = @PlayerLname AND PersonDOB = @PlayerDOB AND @PlayerEmail = @PlayerEmail)
SET @PlayerTypeID = (SELECT PlayerTypeID FROM PLAYER_TYPE WHERE PlayerTypeName = @PlayerType)
IF (@PlayerTypeID IS NULL)
	RAISERROR('PlayerTypeID is NULL, please check spelling',12,1)
BEGIN TRAN T1
	IF (@PersonID IS NULL)
		BEGIN
			INSERT INTO PERSON(PersonFname, PersonLname, PersonDOB, Email)
			VALUES (@PlayerFname, @PlayerLname, @PlayerDOB, @PlayerEmail)
			SET @PersonID = (SELECT SCOPE_IDENTITY())
			INSERT INTO PLAYER(PersonID, PlayerTypeID)
			VALUES (@PersonID, @PlayerTypeID)
		END
	ELSE
		BEGIN
			INSERT INTO PLAYER(PersonID, PlayerTypeID)
			VALUES (@PersonID, @PlayerTypeID)
		END
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1



--SPROC to insert a new player stat, looks up values using nested SPROCs
ALTER PROCEDURE [dbo].[uspInsertNewPlayerStat]
@Fname1 varchar(35),
@Lname1 varchar(35),
@DOB1 DATE,
@StatName1 varchar(35),
@StatAbbrev1 varchar(35),
@PlayerStatDate DATE
AS
DECLARE @PlayerID1 INT
DECLARE @StatID1 INT

EXEC uspGetPlayerID
@Fname = @Fname1,
@Lname = @Lname1,
@DOB = @DOB1,
@PlayerID = @PlayerID1 OUTPUT

EXEC uspGetStatID
@StatName = @StatName1,
@StatAbbrev = @StatAbbrev1,
@StatID = @StatID1 OUTPUT

IF @PlayerID1 IS NULL
	BEGIN
		RAISERROR ('@PlayerID cannot be NULL; please check spelling of player names or their respective date of birth', 12, 1)
		RETURN
	END

IF @StatID1 IS NULL
	BEGIN
		RAISERROR ('@StatID cannot be NULL; please check the spelling of the stat name and stat abbreviation', 12, 1)
		RETURN
	END

BEGIN TRAN T1
	INSERT INTO PLAYER_STATS (PlayerID, StatID, StatDate)
	VALUES (@PlayerID1, @StatID1, @PlayerStatDate)
IF @@ERROR <> 0
	ROLLBACK TRAN M1
ELSE
	COMMIT TRAN M1



--Synthetic Stored Procedure that adds entries to Player_Stats to simulate activity
ALTER PROCEDURE [dbo].[uspSyntheticNewPlayerStats]
@Run INT
AS
--Values that need to be inserted into the PLAYER_STATS Table
DECLARE @SynthPlayerRand INT
DECLARE @SynthPlayerID INT
DECLARE @SynthStatID INT
DECLARE @SynthStatRand INT
DECLARE @SynthStatDate DATE

--Values required for obtaining PlayerID
DECLARE @SynthFname varchar(35)
DECLARE @SynthLname varchar(35)
DECLARE @SynthDOB DATE

--Values required for obtaining StatID
DECLARE @SynthStatName varchar(35)
DECLARE @SynthStatAbbrev varchar(35)

--WHILE Loop
WHILE @Run > 0
BEGIN
	--Create random variables, CASE statements for problem values
	SET @SynthPlayerRand = (SELECT CAST(RAND() * (SELECT COUNT(*) FROM PLAYER) AS INT))
	SET @SynthStatRand = (SELECT CAST (RAND() * (SELECT COUNT(*) FROM [STATS]) AS INT))
	SET @SynthPlayerID = (
		CASE 
			WHEN (@SynthPlayerRand = 0) THEN 1
			ELSE @SynthPlayerRand
		END)
	SET @SynthStatID = (
		CASE 
			WHEN (@SynthStatRand = 0) THEN 12
			ELSE @SynthStatRand
		END)
	--Random date in the last 20ish years
	SET @SynthStatDate = (SELECT GETDATE() - CAST(RAND() * 365 AS INT))

	--Extract necessary info to run SPROC
	SET @SynthFname = (SELECT PE.PersonFname FROM PERSON PE JOIN PLAYER P ON PE.PersonID = P.PersonID WHERE P.PlayerID = @SynthPlayerID)
	SET @SynthLname = (SELECT PE.PersonLname FROM PERSON PE JOIN PLAYER P ON PE.PersonID = P.PersonID WHERE P.PlayerID = @SynthPlayerID)
	SET @SynthDOB = (SELECT PE.PersonDOB FROM PERSON PE JOIN PLAYER P ON PE.PersonID = P.PersonID WHERE P.PlayerID = @SynthPlayerID)
	SET @SynthStatName = (SELECT StatName FROM [STATS] WHERE StatID = @SynthStatID)
	SET @SynthStatAbbrev = (SELECT StatAbbrev FROM [STATS] WHERE StatID = @SynthStatID)

	--EXEC SPROC
	EXEC uspInsertNewPlayerStat
	@Fname1 = @SynthFname,
	@Lname1 = @SynthLname,
	@DOB1 = @SynthDOB,
	@StatName1 = @SynthStatName,
	@StatAbbrev1 = @SynthStatAbbrev,
	@PlayerStatDate = @SynthStatDate

	--Reduce Run Size
	SET @Run = @Run - 1
END
GO


--Check constraint: An active player can only own the team they play for
CREATE FUNCTION fnActivePlayerOnlyOwnsActiveTeam()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT
SET @Ret = 0
IF EXISTS (
	SELECT *
	FROM PERSON P
		JOIN PLAYER PL ON P.PersonID = PL.PersonID
		JOIN [CONTRACT] C ON PL.PlayerID = C.ContractID
		JOIN TEAM T ON C.TeamID = T.TeamID
		JOIN TEAM_OWNER TE ON T.TeamID = TE.TeamID
		JOIN [OWNER] O ON TE.OwnerID = O.OwnerID
	WHERE O.PersonID = PL.PersonID
	AND (SELECT TOP 1 EndDate FROM [CONTRACT] WHERE PlayerID = C.PlayerID ORDER BY BeginDate DESC) IS NOT NULL
	AND C.TeamID <> TE.TeamID)
	SET @Ret = 1
RETURN @Ret
END

ALTER TABLE dbo.TEAM_OWNER with NOCHECK
ADD CONSTRAINT CK_PlayerOwnerTeamsMustBeSame
CHECK (dbo.fnActivePlayerOnlyOwnsActiveTeam() = 0)



--Check constraint: A person cannot be stored as a player more than once
CREATE FUNCTION fnPersonCannotBeMoreThanOnePlayer()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT
SET @Ret = 0
IF EXISTS (
	SELECT PE.PersonFname, PE.PersonLname, PE.PersonDOB, COUNT(*)
	FROM PLAYER P
		JOIN PERSON PE ON P.PersonID = PE.PersonID
	GROUP BY PE.PersonFname, PE.PersonLname, PE.PersonDOB
	HAVING COUNT(*) > 1)
	SET @Ret = 1
RETURN @Ret
END

ALTER TABLE dbo.PLAYER with NOCHECK
ADD CONSTRAINT CK_NoDuplicatePlayerPersonEntries
CHECK (dbo.fnPersonCannotBeMoreThanOnePlayer() = 0)



--Computed Column that calculates the total number of goals a player has scored
CREATE FUNCTION fnCareerGoals(@PlayerID INT)
RETURNS INT
AS
BEGIN
DECLARE @Ret INT
SET @Ret = (SELECT COUNT(*)
			FROM PLAYER P
				JOIN PLAYER_STATS PS ON P.PlayerID = PS.PlayerID
				JOIN [STATS] S ON PS.StatID = S.StatID
			WHERE S.StatName = 'Goals Scored'
			AND P.PlayerID = @PlayerID)
RETURN @Ret
END

ALTER TABLE dbo.PLAYER
ADD [CareerGoals] AS (dbo.fnCareerGoals(PlayerID))



--Computed Column that calculates the total number of active forwards per team
ALTER FUNCTION [dbo].[fnTotalNumberOfActiveForwards](@TeamID INT)
RETURNS INT
AS
BEGIN
DECLARE @Ret INT
SET @Ret = (SELECT COUNT(*)
			FROM TEAM T
				JOIN [CONTRACT] C ON T.TeamID = C.TeamID
				JOIN PLAYER P ON C.PlayerID = P.PlayerID
				JOIN PLAYER_TYPE PT ON P.PlayerTypeID = PT.PlayerTypeID
			WHERE PT.PlayerTypeName = 'forward'
			AND T.TeamID = @TeamID
			AND (C.EndDate IS NULL OR C.EndDate > (SELECT GETDATE())))
RETURN @Ret
END

ALTER TABLE dbo.TEAM
ADD [ActiveForwards] AS (dbo.fnTotalNumberOfActiveForwardsTeamID))



--Create View of Offensive Statistics
CREATE VIEW [dbo].[OffensiveStatistics] AS
(SELECT T.TeamName,
	(SELECT COUNT(*) 
	FROM [STATS] S
		JOIN PLAYER_STATS PS ON S.StatID = PS.StatID
		JOIN PLAYER P ON PS.PlayerID = P.PlayerID
		JOIN [CONTRACT] C ON P.PlayerID = C.ContractID
		JOIN TEAM TE ON C.TeamID = TE.TeamID
	WHERE S.StatName = 'Goals Scored'
	AND TE.TeamID = T.TeamID) AS Goals_Scored,
	(SELECT COUNT(*) 
	FROM [STATS] S
		JOIN PLAYER_STATS PS ON S.StatID = PS.StatID
		JOIN PLAYER P ON PS.PlayerID = P.PlayerID
		JOIN [CONTRACT] C ON P.PlayerID = C.ContractID
		JOIN TEAM TE ON C.TeamID = TE.TeamID
	WHERE S.StatName = 'Assists'
	AND TE.TeamID = T.TeamID) AS Assists,
	(SELECT COUNT(*) 
	FROM [STATS] S
		JOIN PLAYER_STATS PS ON S.StatID = PS.StatID
		JOIN PLAYER P ON PS.PlayerID = P.PlayerID
		JOIN [CONTRACT] C ON P.PlayerID = C.ContractID
		JOIN TEAM TE ON C.TeamID = TE.TeamID
	WHERE S.StatName = 'Shots'
	AND TE.TeamID = T.TeamID) AS Shots,
	(SELECT COUNT(*) 
	FROM [STATS] S
		JOIN PLAYER_STATS PS ON S.StatID = PS.StatID
		JOIN PLAYER P ON PS.PlayerID = P.PlayerID
		JOIN [CONTRACT] C ON P.PlayerID = C.ContractID
		JOIN TEAM TE ON C.TeamID = TE.TeamID
	WHERE S.StatName = 'Shots on Goal'
	AND TE.TeamID = T.TeamID) AS Shots_On_Goal
FROM TEAM T)



--Create View That Categorizes Teams Based On How Much They Spend on Payroll And How Many Goals They've Scored
CREATE VIEW [TeamSpending] AS
(SELECT T.TeamName, T.TotalSalary, (CASE
	WHEN (T.TeamID IN (SELECT TOP 5 TeamID FROM TEAM ORDER BY TotalSalary DESC)) THEN 'Top 5 Spender'
	WHEN (T.TeamID IN (SELECT TOP 5 TeamID FROM TEAM ORDER BY TotalSalary ASC)) THEN 'Bottom 5 Spender'
	ELSE 'Middle of the Pack'
	END) AS Spending_Type, 
	(SELECT TOP 100 PERCENT COUNT(*)
			FROM TEAM TE
				JOIN [CONTRACT] C ON TE.TeamID = C.TeamID
				JOIN PLAYER P ON C.PlayerID = P.PlayerID
				JOIN PLAYER_STATS PS ON P.PlayerID = PS.PlayerID
				JOIN [STATS] S ON PS.StatID = S.StatID
			WHERE S.StatName = 'Goals Scored' AND TE.TeamID = T.TeamID) as Goals_Scored
FROM TEAM T)