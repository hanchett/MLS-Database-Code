USE [master]
GO
/****** Object:  Database [MLS]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE DATABASE [MLS]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'MLS', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MLS.mdf' , SIZE = 138432KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'MLS_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\MLS_log.ldf' , SIZE = 1502208KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [MLS] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [MLS].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [MLS] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [MLS] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [MLS] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [MLS] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [MLS] SET ARITHABORT OFF 
GO
ALTER DATABASE [MLS] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [MLS] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [MLS] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [MLS] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [MLS] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [MLS] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [MLS] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [MLS] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [MLS] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [MLS] SET  ENABLE_BROKER 
GO
ALTER DATABASE [MLS] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [MLS] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [MLS] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [MLS] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [MLS] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [MLS] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [MLS] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [MLS] SET RECOVERY FULL 
GO
ALTER DATABASE [MLS] SET  MULTI_USER 
GO
ALTER DATABASE [MLS] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [MLS] SET DB_CHAINING OFF 
GO
ALTER DATABASE [MLS] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [MLS] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [MLS] SET DELAYED_DURABILITY = DISABLED 
GO
EXEC sys.sp_db_vardecimal_storage_format N'MLS', N'ON'
GO
USE [MLS]
GO
/****** Object:  UserDefinedFunction [dbo].[fnActivePlayerOnlyOwnsActiveTeam]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnActivePlayerOnlyOwnsActiveTeam]()
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
GO
/****** Object:  UserDefinedFunction [dbo].[fnCareerGoals]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnCareerGoals](@PlayerID INT)
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
GO
/****** Object:  UserDefinedFunction [dbo].[fnCountGamesPlayedByTeam]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnCountGamesPlayedByTeam](@TeamID INT)
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
GO
/****** Object:  UserDefinedFunction [dbo].[fnMaxTeamOwners]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnMaxTeamOwners]()
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
GO
/****** Object:  UserDefinedFunction [dbo].[fnNoContractEndDateBeforeStartDate]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnNoContractEndDateBeforeStartDate]()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT * FROM [CONTRACT]
		WHERE EndDate < BeginDate)
SET @RET = 1
RETURN @RET
END
GO
/****** Object:  UserDefinedFunction [dbo].[fnNoNegativeScores]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnNoNegativeScores]()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT * FROM GAME
		WHERE HomeScore < 0 OR AwayScore < 0)
SET @RET = 1
RETURN @RET
END
GO
/****** Object:  UserDefinedFunction [dbo].[fnOperationsOneTeam]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnOperationsOneTeam]()
RETURNS INT
AS
BEGIN
DECLARE @RET INT = 0
IF EXISTS(SELECT e.EmployeeID, COUNT(*) FROM EMPLOYEE e
		JOIN TEAM_EMPLOYEE te ON e.EmployeeID = te.EmployeeID
		JOIN TEAM t ON te.TeamID = t.TeamID
		JOIN EMPLOYEE_TYPE et ON e.EmployeeTypeID = et.EmployeeTypeID
		WHERE et.EmployeeTypeName = 'Operations'
		GROUP BY e.EmployeeID
		HAVING COUNT(*) > 1)
SET @RET = 1
RETURN @RET
END
GO
/****** Object:  UserDefinedFunction [dbo].[fnPersonCannotBeMoreThanOnePlayer]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnPersonCannotBeMoreThanOnePlayer]()
RETURNS INT
AS
BEGIN
DECLARE @Ret INT
SET @Ret = 0
IF EXISTS (
	SELECT P.PlayerID, P.PersonID, COUNT(*)
	FROM PLAYER P
	GROUP BY P.PlayerID, P.PersonID
	HAVING COUNT(*) > 1)
	SET @Ret = 1
RETURN @Ret
END
GO
/****** Object:  UserDefinedFunction [dbo].[fnPlayersManaged]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnPlayersManaged](@AgentID INT)
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
GO
/****** Object:  UserDefinedFunction [dbo].[fnTotalGamesStadium]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTotalGamesStadium](@StadiumID INT)
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
GO
/****** Object:  UserDefinedFunction [dbo].[fnTotalNumberEmployees]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTotalNumberEmployees](@TeamID INT)
RETURNS INT
AS 
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT COUNT(e.EmployeeID) FROM EMPLOYEE e
	JOIN TEAM_EMPLOYEE te on e.EmployeeID = te.EmployeeID
	JOIN TEAM t on te.TeamID = t.TeamID
	WHERE t.TeamID = @TeamID)
SET @RET = (CASE WHEN (@RET IS NULL) THEN 0 ELSE @RET END)
RETURN @RET
END
GO
/****** Object:  UserDefinedFunction [dbo].[fnTotalNumberOfActiveForwards]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnTotalNumberOfActiveForwards](@TeamID INT)
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

GO
/****** Object:  UserDefinedFunction [dbo].[onlyThreeDPs]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[onlyThreeDPs]()
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
/****** Object:  UserDefinedFunction [dbo].[PlayerCareerEarnings]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[PlayerCareerEarnings](@PlayerID INT)
RETURNS INT 
AS
BEGIN
DECLARE @RET INT = 0
SET @RET = (SELECT SUM(c.Salary) FROM CONTRACT c 
            WHERE c.PlayerID = @PlayerID)
RETURN @RET
END
GO
/****** Object:  UserDefinedFunction [dbo].[signingFitsSalaryCap]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[signingFitsSalaryCap]() 
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
/****** Object:  UserDefinedFunction [dbo].[TeamSalary]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[TeamSalary](@TeamID INT)
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
/****** Object:  Table [dbo].[AGENT]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AGENT](
	[AgentID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[AgentName] [varchar](35) NOT NULL,
	[AgentDesc] [varchar](50) NULL,
	[PlayersManaged]  AS ([dbo].[fnPlayersManaged]([AgentID])),
PRIMARY KEY CLUSTERED 
(
	[AgentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CLAUSE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CLAUSE](
	[ClauseID] [int] IDENTITY(1,1) NOT NULL,
	[ClauseName] [varchar](35) NOT NULL,
	[ClausetDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ClauseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CONFERENCE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CONFERENCE](
	[ConferenceID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ConferenceName] [varchar](35) NOT NULL,
	[ConferenceDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[ConferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CONTRACT]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CONTRACT](
	[ContractID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BeginDate] [date] NULL,
	[EndDate] [date] NULL,
	[Salary] [numeric](9, 1) NOT NULL,
	[ContractDesc] [varchar](50) NULL,
	[TeamID] [int] NOT NULL,
	[PlayerID] [int] NOT NULL,
 CONSTRAINT [PK__CONTRACT__C90D34097F10F6BA] PRIMARY KEY CLUSTERED 
(
	[ContractID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CONTRACT_CLAUSE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CONTRACT_CLAUSE](
	[ContractClauseID] [int] IDENTITY(1,1) NOT NULL,
	[ContractClauseStartDate] [date] NOT NULL,
	[ContractClauseEndDate] [date] NULL,
	[ClauseID] [int] NOT NULL,
	[ContractID] [int] NOT NULL,
 CONSTRAINT [PK__CONTRACT__DAEA0F39B2F66CF4] PRIMARY KEY CLUSTERED 
(
	[ContractClauseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EMPLOYEE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EMPLOYEE](
	[EmployeeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PersonID] [int] NOT NULL,
	[EmployeeTypeID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EMPLOYEE_TYPE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EMPLOYEE_TYPE](
	[EmployeeTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[EmployeeTypeName] [varchar](35) NOT NULL,
	[EmployeeTypeDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmployeeTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GAME]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GAME](
	[GameID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[HomeScore] [int] NOT NULL,
	[AwayScore] [int] NOT NULL,
	[GameDate] [date] NOT NULL,
	[GameTypeID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[GameID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GAME_TEAM]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GAME_TEAM](
	[GameTeamID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GameID] [int] NOT NULL,
	[TeamID] [int] NOT NULL,
	[GameTeamHAID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[GameTeamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GAME_TEAM_HA]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GAME_TEAM_HA](
	[GameTeamHAID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GameTeamHAName] [varchar](35) NOT NULL,
	[GameTeamHADesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[GameTeamHAID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GAME_TYPE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GAME_TYPE](
	[GameTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[GameTypeName] [varchar](35) NOT NULL,
	[GameTypeDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[GameTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[LOCATION]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[LOCATION](
	[LocationID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[LocationName] [varchar](35) NOT NULL,
	[LocationDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[LocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OWNER]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OWNER](
	[OwnerID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PersonID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PERSON]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PERSON](
	[PersonID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PersonFname] [varchar](35) NOT NULL,
	[PersonLname] [varchar](35) NOT NULL,
	[PersonDOB] [date] NOT NULL,
	[PhoneNumber] [varchar](10) NULL,
	[Email] [varchar](35) NULL,
PRIMARY KEY CLUSTERED 
(
	[PersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PITCH]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PITCH](
	[PitchID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PitchName] [varchar](35) NOT NULL,
	[PitchDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[PitchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PLAYER]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PLAYER](
	[PlayerID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PlayerTypeID] [int] NOT NULL,
	[PersonID] [int] NOT NULL,
	[PlayerNickName] [varchar](35) NULL,
	[CareerGoals]  AS ([dbo].[fnCareerGoals]([PlayerID])),
	[CareerEarnings]  AS ([dbo].[PlayerCareerEarnings]([PlayerID])),
PRIMARY KEY CLUSTERED 
(
	[PlayerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PLAYER_AGENT]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PLAYER_AGENT](
	[PlayerAgentID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NULL,
	[PlayerID] [int] NOT NULL,
	[AgentID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PlayerAgentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PLAYER_STATS]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PLAYER_STATS](
	[PlayerStatID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PlayerID] [int] NOT NULL,
	[StatID] [int] NOT NULL,
	[StatDate] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PlayerStatID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[PLAYER_TYPE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PLAYER_TYPE](
	[PlayerTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[PlayerTypeName] [varchar](35) NOT NULL,
	[PlayerTypeDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[PlayerTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[STADIUM]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[STADIUM](
	[StadiumID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[StadiumName] [varchar](35) NOT NULL,
	[StadiumDesc] [varchar](50) NULL,
	[Capacity] [int] NOT NULL,
	[LocationID] [int] NOT NULL,
	[StadiumTypeID] [int] NOT NULL,
	[PitchID] [int] NOT NULL,
	[TotalGamesPlayed]  AS ([dbo].[fnTotalGamesStadium]([StadiumID])),
PRIMARY KEY CLUSTERED 
(
	[StadiumID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[STADIUM_TYPE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[STADIUM_TYPE](
	[StadiumTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[StadiumTypeName] [varchar](35) NOT NULL,
	[StadiumTypeDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[StadiumTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[STATS]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[STATS](
	[StatID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[StatName] [varchar](35) NOT NULL,
	[StatDesc] [varchar](50) NULL,
	[StatAbbrev] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[StatID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TEAM]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TEAM](
	[TeamID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TeamName] [varchar](35) NOT NULL,
	[TeamDesc] [varchar](50) NULL,
	[StadiumID] [int] NOT NULL,
	[TeamTypeID] [int] NOT NULL,
	[GamesPlayed]  AS ([dbo].[fnCountGamesPlayedByTeam]([TeamID])),
	[NumberOfEmployees]  AS ([dbo].[fnTotalNumberEmployees]([TeamID])),
	[TotalSalary]  AS ([dbo].[TeamSalary]([TeamID])),
	[ActiveForwards]  AS ([dbo].[fnTotalNumberOfActiveForwards]([TeamID])),
PRIMARY KEY CLUSTERED 
(
	[TeamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TEAM_CONFERENCE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEAM_CONFERENCE](
	[TeamConferenceID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TeamID] [int] NOT NULL,
	[ConferenceID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TeamConferenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TEAM_EMPLOYEE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEAM_EMPLOYEE](
	[TeamEmployeeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[TeamID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TeamEmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TEAM_OWNER]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TEAM_OWNER](
	[TeamOwnerID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[SharePercent] [numeric](3, 2) NOT NULL,
	[StartDate] [date] NOT NULL,
	[EndDate] [date] NULL,
	[OwnerID] [int] NOT NULL,
	[TeamID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TeamOwnerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TEAM_PLAYER_TRANSACTION]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TEAM_PLAYER_TRANSACTION](
	[TeamPlayerTransactionID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TeamPlayerTransactionDate] [date] NOT NULL,
	[TeamPlayerTransactionDesc] [varchar](50) NULL,
	[TransactionID] [int] NOT NULL,
	[ContractID] [int] NOT NULL,
 CONSTRAINT [PK__TEAM_PLA__C26C9CB1E00367F4] PRIMARY KEY CLUSTERED 
(
	[TeamPlayerTransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TEAM_TYPE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TEAM_TYPE](
	[TeamTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TeamTypeName] [varchar](35) NOT NULL,
	[TeamTypeDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[TeamTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRANSACTION]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRANSACTION](
	[TransactionID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TransactionName] [varchar](35) NOT NULL,
	[TransactionDesc] [varchar](50) NULL,
	[TransactionTypeID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TransactionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TRANSACTION_TYPE]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TRANSACTION_TYPE](
	[TransactionTypeID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[TransactionTypeName] [varchar](35) NOT NULL,
	[TransactionTypeDesc] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[TransactionTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[Standings]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Standings]
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
/****** Object:  View [dbo].[WesternConferenceStandings]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[WesternConferenceStandings]
AS 
SELECT * FROM Standings
WHERE ConferenceName = 'Western Conference'
GO
/****** Object:  View [dbo].[EasternConferenceStandings]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[EasternConferenceStandings]
AS 
SELECT * FROM Standings
WHERE ConferenceName = 'Eastern Conference'
GO
/****** Object:  View [dbo].[Contracted Player List]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Contracted Player List] AS 
(SELECT PersonFname, PersonLname, TeamName, c.BeginDate FROM PLAYER p
JOIN [CONTRACT] c on p.PlayerID = c.PlayerID
JOIN TEAM t on c.TeamID = t.TeamID
JOIN PERSON per on p.PersonID = per.PersonID
WHERE (c.EndDate IS NULL))
GO
/****** Object:  View [dbo].[Number of MLS Cup Games a Team Has Played]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Number of MLS Cup Games a Team Has Played] AS 
(SELECT t.TeamName as Team_Name , COUNT(g.GameID) as Number_of_Games FROM TEAM t
JOIN GAME_TEAM gt ON t.TeamID = gt.TeamID
JOIN GAME g ON gt.GameID = g.GameID
JOIN GAME_TYPE gty ON g.GameTypeID = gty.GameTypeID
WHERE gty.GameTypeName = 'MLS Cup'
GROUP BY t.TeamName)
GO
/****** Object:  View [dbo].[OffensiveStatistics]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  View [dbo].[Players Currently Managed By An Agent]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Players Currently Managed By An Agent] AS 
(SELECT a.AgentName, per.PersonFname, per.PersonLname, t.TeamName FROM AGENT a
JOIN PLAYER_AGENT pa on a.AgentID = a.AgentID
JOIN PLAYER p on pa.PlayerID = p.PlayerID
JOIN PERSON per on p.PersonID = per.PersonID
JOIN EMPLOYEE e on per.PersonID = e.EmployeeID
JOIN TEAM_EMPLOYEE te on e.EmployeeID = te.EmployeeID
JOIN TEAM t on te.TeamID = t.TeamID
WHERE (pa.EndDate IS NULL))
GO
/****** Object:  View [dbo].[Team Owner List]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[Team Owner List] AS
(SELECT PersonFname, PersonLname, TeamName FROM [OWNER] o
JOIN PERSON p on o.PersonID = p.PersonID
JOIN TEAM_OWNER tow on o.OwnerID = tow.OwnerID
JOIN TEAM t on tow.TeamID = t.TeamID)
GO
/****** Object:  View [dbo].[TeamRosters]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[TeamRosters]
AS
SELECT t.TeamName, per.PersonFname, per.PersonLname, c.Salary, (CASE WHEN c.Salary >= 480625 THEN 'DP' WHEN c.Salary < 480625 AND c.Salary >= 80000 THEN 'Normal Player' WHEN c.Salary > 65000 AND c.Salary < 80000 THEN 'Senior Player' ELSE 'Rookie' END) 
             AS SalaryType
FROM   dbo.TEAM AS t INNER JOIN
             dbo.CONTRACT AS c ON c.TeamID = t.TeamID INNER JOIN
             dbo.PLAYER AS p ON p.PlayerID = c.PlayerID INNER JOIN
             dbo.PERSON AS per ON per.PersonID = p.PersonID
WHERE (c.EndDate IS NULL)
GROUP BY t.TeamName, per.PersonFname, per.PersonLname, c.Salary, (CASE WHEN c.Salary >= 480625 THEN 'DP' WHEN c.Salary < 480625 AND c.Salary >= 80000 THEN 'Normal Player' WHEN c.Salary > 65000 AND c.Salary < 80000 THEN 'Senior Player' ELSE 'Rookie' END)

GO
/****** Object:  View [dbo].[TeamSpending]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[TeamSpending] AS
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
GO
/****** Object:  View [dbo].[WinPoints]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[WinPoints]
AS
(SELECT t.TeamName, 
(SELECT COUNT(*) * 3 as NumWins FROM GAME g
JOIN GAME_TEAM gt on g.GameID = gt.GameID
JOIN TEAM t ON t.TeamID = gt.TeamID
JOIN GAME_TEAM_HA gth ON gth.GameTeamHAID = gt.GameTeamHAID
WHERE (gth.GameTeamHAName = 'Home' AND g.HomeScore > AwayScore)
OR (gth.GameTeamHAName = 'Away' AND g.AwayScore >  g.HomeScore)
GROUP BY t.TeamID) 
+ 
(SELECT COUNT(*) as NumTies FROM GAME g
JOIN GAME_TEAM gt on g.GameID = gt.GameID
JOIN TEAM t ON t.TeamID = gt.TeamID
JOIN GAME_TEAM_HA gth ON gth.GameTeamHAID = gt.GameTeamHAID
WHERE  g.HomeScore = AwayScore
GROUP BY t.TeamID) AS NumPoints 
FROM TEAM t
GROUP BY T.TeamName)
GO
/****** Object:  Index [Contract_PlayerID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Contract_PlayerID] ON [dbo].[CONTRACT]
(
	[PlayerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Contract_TeamID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Contract_TeamID] ON [dbo].[CONTRACT]
(
	[TeamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Employee_EmployeeTypeID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Employee_EmployeeTypeID] ON [dbo].[EMPLOYEE]
(
	[EmployeeTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Employee_PersonID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Employee_PersonID] ON [dbo].[EMPLOYEE]
(
	[PersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [Person_Fname_Lname_DOB]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Person_Fname_Lname_DOB] ON [dbo].[PERSON]
(
	[PersonFname] ASC,
	[PersonLname] ASC,
	[PersonDOB] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Player_PersonID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Player_PersonID] ON [dbo].[PLAYER]
(
	[PersonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Player_PlayerTypeID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Player_PlayerTypeID] ON [dbo].[PLAYER]
(
	[PlayerTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [PlayerStats_PlayerID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [PlayerStats_PlayerID] ON [dbo].[PLAYER_STATS]
(
	[PlayerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [PlayerStats_StatID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [PlayerStats_StatID] ON [dbo].[PLAYER_STATS]
(
	[StatID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [Team_TeamTypeID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [Team_TeamTypeID] ON [dbo].[TEAM]
(
	[TeamTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [TeamEmployee_EmployeeID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [TeamEmployee_EmployeeID] ON [dbo].[TEAM_EMPLOYEE]
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [TeamEmployee_TeamID]    Script Date: 3/19/2017 7:20:16 PM ******/
CREATE NONCLUSTERED INDEX [TeamEmployee_TeamID] ON [dbo].[TEAM_EMPLOYEE]
(
	[TeamID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CONTRACT]  WITH CHECK ADD FOREIGN KEY([PlayerID])
REFERENCES [dbo].[PLAYER] ([PlayerID])
GO
ALTER TABLE [dbo].[CONTRACT]  WITH CHECK ADD FOREIGN KEY([TeamID])
REFERENCES [dbo].[TEAM] ([TeamID])
GO
ALTER TABLE [dbo].[CONTRACT_CLAUSE]  WITH CHECK ADD  CONSTRAINT [FK__CONTRACT___Claus__05D8E0BE] FOREIGN KEY([ClauseID])
REFERENCES [dbo].[CLAUSE] ([ClauseID])
GO
ALTER TABLE [dbo].[CONTRACT_CLAUSE] CHECK CONSTRAINT [FK__CONTRACT___Claus__05D8E0BE]
GO
ALTER TABLE [dbo].[CONTRACT_CLAUSE]  WITH CHECK ADD FOREIGN KEY([ContractID])
REFERENCES [dbo].[CONTRACT] ([ContractID])
GO
ALTER TABLE [dbo].[EMPLOYEE]  WITH CHECK ADD FOREIGN KEY([EmployeeTypeID])
REFERENCES [dbo].[EMPLOYEE_TYPE] ([EmployeeTypeID])
GO
ALTER TABLE [dbo].[EMPLOYEE]  WITH CHECK ADD FOREIGN KEY([PersonID])
REFERENCES [dbo].[PERSON] ([PersonID])
GO
ALTER TABLE [dbo].[GAME]  WITH CHECK ADD FOREIGN KEY([GameTypeID])
REFERENCES [dbo].[GAME_TYPE] ([GameTypeID])
GO
ALTER TABLE [dbo].[GAME_TEAM]  WITH CHECK ADD FOREIGN KEY([GameID])
REFERENCES [dbo].[GAME] ([GameID])
GO
ALTER TABLE [dbo].[GAME_TEAM]  WITH CHECK ADD FOREIGN KEY([GameTeamHAID])
REFERENCES [dbo].[GAME_TEAM_HA] ([GameTeamHAID])
GO
ALTER TABLE [dbo].[GAME_TEAM]  WITH CHECK ADD FOREIGN KEY([TeamID])
REFERENCES [dbo].[TEAM] ([TeamID])
GO
ALTER TABLE [dbo].[OWNER]  WITH CHECK ADD FOREIGN KEY([PersonID])
REFERENCES [dbo].[PERSON] ([PersonID])
GO
ALTER TABLE [dbo].[PLAYER]  WITH CHECK ADD FOREIGN KEY([PersonID])
REFERENCES [dbo].[PERSON] ([PersonID])
GO
ALTER TABLE [dbo].[PLAYER]  WITH CHECK ADD FOREIGN KEY([PlayerTypeID])
REFERENCES [dbo].[PLAYER_TYPE] ([PlayerTypeID])
GO
ALTER TABLE [dbo].[PLAYER_AGENT]  WITH CHECK ADD FOREIGN KEY([AgentID])
REFERENCES [dbo].[AGENT] ([AgentID])
GO
ALTER TABLE [dbo].[PLAYER_AGENT]  WITH CHECK ADD FOREIGN KEY([PlayerID])
REFERENCES [dbo].[PLAYER] ([PlayerID])
GO
ALTER TABLE [dbo].[PLAYER_STATS]  WITH CHECK ADD FOREIGN KEY([PlayerID])
REFERENCES [dbo].[PLAYER] ([PlayerID])
GO
ALTER TABLE [dbo].[PLAYER_STATS]  WITH CHECK ADD FOREIGN KEY([StatID])
REFERENCES [dbo].[STATS] ([StatID])
GO
ALTER TABLE [dbo].[STADIUM]  WITH CHECK ADD FOREIGN KEY([LocationID])
REFERENCES [dbo].[LOCATION] ([LocationID])
GO
ALTER TABLE [dbo].[STADIUM]  WITH CHECK ADD FOREIGN KEY([PitchID])
REFERENCES [dbo].[PITCH] ([PitchID])
GO
ALTER TABLE [dbo].[STADIUM]  WITH CHECK ADD FOREIGN KEY([StadiumTypeID])
REFERENCES [dbo].[STADIUM_TYPE] ([StadiumTypeID])
GO
ALTER TABLE [dbo].[TEAM]  WITH CHECK ADD FOREIGN KEY([StadiumID])
REFERENCES [dbo].[STADIUM] ([StadiumID])
GO
ALTER TABLE [dbo].[TEAM]  WITH CHECK ADD FOREIGN KEY([TeamTypeID])
REFERENCES [dbo].[TEAM_TYPE] ([TeamTypeID])
GO
ALTER TABLE [dbo].[TEAM_CONFERENCE]  WITH CHECK ADD FOREIGN KEY([ConferenceID])
REFERENCES [dbo].[CONFERENCE] ([ConferenceID])
GO
ALTER TABLE [dbo].[TEAM_CONFERENCE]  WITH CHECK ADD FOREIGN KEY([TeamID])
REFERENCES [dbo].[TEAM] ([TeamID])
GO
ALTER TABLE [dbo].[TEAM_EMPLOYEE]  WITH CHECK ADD FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[EMPLOYEE] ([EmployeeID])
GO
ALTER TABLE [dbo].[TEAM_EMPLOYEE]  WITH CHECK ADD FOREIGN KEY([TeamID])
REFERENCES [dbo].[TEAM] ([TeamID])
GO
ALTER TABLE [dbo].[TEAM_OWNER]  WITH CHECK ADD FOREIGN KEY([OwnerID])
REFERENCES [dbo].[OWNER] ([OwnerID])
GO
ALTER TABLE [dbo].[TEAM_OWNER]  WITH CHECK ADD FOREIGN KEY([TeamID])
REFERENCES [dbo].[TEAM] ([TeamID])
GO
ALTER TABLE [dbo].[TEAM_PLAYER_TRANSACTION]  WITH CHECK ADD FOREIGN KEY([ContractID])
REFERENCES [dbo].[CONTRACT] ([ContractID])
GO
ALTER TABLE [dbo].[TEAM_PLAYER_TRANSACTION]  WITH CHECK ADD  CONSTRAINT [FK__TEAM_PLAY__Trans__00200768] FOREIGN KEY([TransactionID])
REFERENCES [dbo].[TRANSACTION] ([TransactionID])
GO
ALTER TABLE [dbo].[TEAM_PLAYER_TRANSACTION] CHECK CONSTRAINT [FK__TEAM_PLAY__Trans__00200768]
GO
ALTER TABLE [dbo].[TRANSACTION]  WITH CHECK ADD FOREIGN KEY([TransactionTypeID])
REFERENCES [dbo].[TRANSACTION_TYPE] ([TransactionTypeID])
GO
ALTER TABLE [dbo].[CONTRACT]  WITH CHECK ADD  CONSTRAINT [ck_NoContractEndDateBeforeStartDate] CHECK  (([dbo].[fnNoContractEndDateBeforeStartDate]()=(0)))
GO
ALTER TABLE [dbo].[CONTRACT] CHECK CONSTRAINT [ck_NoContractEndDateBeforeStartDate]
GO
ALTER TABLE [dbo].[CONTRACT]  WITH CHECK ADD  CONSTRAINT [NoBreakingSalaryCap] CHECK  (([dbo].[signingFitsSalaryCap]()=(0)))
GO
ALTER TABLE [dbo].[CONTRACT] CHECK CONSTRAINT [NoBreakingSalaryCap]
GO
ALTER TABLE [dbo].[CONTRACT]  WITH CHECK ADD  CONSTRAINT [OnlyThreeDP] CHECK  (([dbo].[onlyThreeDPs]()=(0)))
GO
ALTER TABLE [dbo].[CONTRACT] CHECK CONSTRAINT [OnlyThreeDP]
GO
ALTER TABLE [dbo].[GAME_TEAM]  WITH CHECK ADD  CONSTRAINT [ck_NoNegativeScores] CHECK  (([dbo].[fnNoNegativeScores]()=(0)))
GO
ALTER TABLE [dbo].[GAME_TEAM] CHECK CONSTRAINT [ck_NoNegativeScores]
GO
ALTER TABLE [dbo].[PLAYER]  WITH NOCHECK ADD  CONSTRAINT [CK_NoDuplicatePlayerPersonEntries] CHECK  (([dbo].[fnPersonCannotBeMoreThanOnePlayer]()=(0)))
GO
ALTER TABLE [dbo].[PLAYER] CHECK CONSTRAINT [CK_NoDuplicatePlayerPersonEntries]
GO
ALTER TABLE [dbo].[TEAM_EMPLOYEE]  WITH CHECK ADD  CONSTRAINT [ck_OperationsOneTeam] CHECK  (([dbo].[fnOperationsOneTeam]()=(0)))
GO
ALTER TABLE [dbo].[TEAM_EMPLOYEE] CHECK CONSTRAINT [ck_OperationsOneTeam]
GO
ALTER TABLE [dbo].[TEAM_OWNER]  WITH CHECK ADD  CONSTRAINT [ck_NoMoreThan3TeamsPerOwner] CHECK  (([dbo].[fnMaxTeamOwners]()=(0)))
GO
ALTER TABLE [dbo].[TEAM_OWNER] CHECK CONSTRAINT [ck_NoMoreThan3TeamsPerOwner]
GO
ALTER TABLE [dbo].[TEAM_OWNER]  WITH NOCHECK ADD  CONSTRAINT [CK_PlayerOwnerTeamsMustBeSame] CHECK  (([dbo].[fnActivePlayerOnlyOwnsActiveTeam]()=(0)))
GO
ALTER TABLE [dbo].[TEAM_OWNER] CHECK CONSTRAINT [CK_PlayerOwnerTeamsMustBeSame]
GO
/****** Object:  StoredProcedure [dbo].[addConference]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Creates a new conference 
CREATE PROC [dbo].[addConference]
@ConferenceName varchar(35)

AS 
BEGIN TRAN T1
    INSERT INTO CONFERENCE([ConferenceName])
    VALUES(@ConferenceName)
IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE    
    COMMIT TRAN T1



GO
/****** Object:  StoredProcedure [dbo].[addNewTeam]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- A stored procedure that adds a new team, stadium, field and division 
CREATE PROC [dbo].[addNewTeam]
@TeamName varchar(35),
@StadiumName varchar(35),
@Capacity INT,
@StadiumTypeName varchar(35),
@PitchName varchar(35),
@LocationName varchar(35),
@TeamTypeName varchar(35),
@ConferenceName varchar(35)
AS

DECLARE @StadiumID INT
DECLARE @ConferenceID INT
DECLARE @TeamTypeID INT
DECLARE @LocationID INT
DECLARE @PitchID INT
DECLARE @StadiumTypeID INT
DECLARE @TeamID INT 

SET @ConferenceID = (SELECT ConferenceID FROM CONFERENCE WHERE ConferenceName = @ConferenceName)
SET @TeamTypeID = (SELECT TeamTypeID FROM TEAM_TYPE WHERE TeamTypeName = @TeamTypeName)
SET @LocationID = (SELECT LocationID FROM [LOCATION] WHERE LocationName = @LocationName)
SET @PitchID = (SELECT PitchID FROM PITCH WHERE PitchName = @PitchName)
SET @StadiumTypeID = (SELECT StadiumTypeID FROM STADIUM_TYPE WHERE StadiumTypeName = @StadiumTypeName)

BEGIN TRAN T1
    INSERT INTO STADIUM([StadiumName], [Capacity], [LocationID], [StadiumTypeID], [PitchID])
    VALUES(@StadiumName, @Capacity, @LocationID, @StadiumTypeID, @PitchID)

    SET @StadiumID = (SELECT SCOPE_IDENTITY())

    INSERT INTO TEAM([TeamName], [StadiumID], [TeamTypeID])
    VALUES(@TeamName, @StadiumID, @TeamTypeID)

    SET @TeamID = (SELECT SCOPE_IDENTITY())

    INSERT INTO TEAM_CONFERENCE([TeamID], [ConferenceID])
    VALUES(@TeamID, @ConferenceID)

IF @@ERROR <> 0
    ROLLBACK TRAN T1
ELSE
    COMMIT TRAN T1



GO
/****** Object:  StoredProcedure [dbo].[clauseContractSynth]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[getEmployeeID]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[getEmployeeID]
@Fname varchar(35),
@Lname varchar(35),
@DOB date,
@Email varchar(35),
@EmployeeTypeName varchar(35),
@EmployeeID INT OUTPUT
AS
DECLARE @EmployeeTypeID INT 
DECLARE @PersonID INT
BEGIN
	/* Have to retreieve PersonID and EmployeeTypeID before finding EmployeeID */
	SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @Fname AND PersonLname = @Lname AND PersonDOB = @DOB AND Email = @Email)
	SET @EmployeeTypeID = (SELECT EmployeeTypeID FROM EMPLOYEE_TYPE WHERE EmployeeTypeName = @EmployeeTypeName)

	SET @EmployeeID = (SELECT EmployeeID FROM EMPLOYEE WHERE PersonID = @PersonID AND EmployeeTypeID = @EmployeeTypeID)
END

GO
/****** Object:  StoredProcedure [dbo].[getEmployeeIDForTeamEmployee]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[getEmployeeIDForTeamEmployee]
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
GO
/****** Object:  StoredProcedure [dbo].[getPlayerID]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[getPlayerID] 
@PlayerFname varchar(35),
@PlayerLname varchar(35),
@DOB date,
@PlayerID INT OUTPUT
AS
BEGIN
    SET @PlayerID = (SELECT TOP 1 p.PlayerID FROM PLAYER p 
					 JOIN PERSON per ON per.PersonID = p.PersonID
					 WHERE per.PersonFname = @PlayerFname
					 AND per.PersonLname = @PlayerLname
					 AND per.PersonDOB = @DOB
					 )
END

GO
/****** Object:  StoredProcedure [dbo].[getTeamID]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[getTeamID] 
@TeamName varchar(35),
@TeamID INT OUTPUT
AS
BEGIN
    SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamName = @TeamName)
END

GO
/****** Object:  StoredProcedure [dbo].[newContract]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[newContract]
@Fname varchar(35),
@Lname varchar(35),
@DOB1 date, 
@TeamName1 varchar(35),
@Salary numeric(10, 2),
@BeginDate date,
@EndDate date,
@ContractID INT OUTPUT

AS

DECLARE @PlayerID1 INT
DECLARE @TeamID1 INT 
DECLARE @CurrentContractID INT


EXEC getPlayerID 
@PlayerFname = @Fname,
@PlayerLname = @Lname,
@DOB = @DOB1,
@PlayerID = @PlayerID1 OUTPUT

EXEC getTeamID
@TeamName = @TeamName1,
@TeamID = @TeamID1 OUTPUT

IF @PlayerID1 is null
    BEGIN 
        RAISERROR('The player you entered does not exist', 12, 1)
        PRINT('Please enter a valid player.')
        RETURN 
    END

IF @TeamID1 is null
    BEGIN 
        RAISERROR('The team you entered does not exist', 12, 1)
        PRINT('Please enter a valid team.')
        RETURN 
    END

SET @CurrentContractID = (SELECT ContractID FROM CONTRACT WHERE PlayerID = @PlayerID1 AND EndDate is null)
	
BEGIN TRAN T1
	IF @CurrentContractID is not null
		BEGIN
			UPDATE CONTRACT 
			SET EndDate = (SELECT GETDATE())
			WHERE PlayerID = @PlayerID1 
			AND EndDate is null
		END

    INSERT INTO CONTRACT([BeginDate], [EndDate], [TeamID], [PlayerID], [Salary])
    VALUES(@BeginDate, @EndDate, @TeamID1, @PlayerID1, @Salary)

	SET @ContractID = (SELECT SCOPE_IDENTITY())

IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[newLocation]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[newLocation] 
@LocationName varchar(35),
@LocationDesc varchar(35)

AS 

BEGIN TRAN T1
    INSERT INTO LOCATION([LocationName], [LocationDesc])
    VALUES(@LocationName, @LocationDesc)

IF @@ERROR <> 0
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[newPitch]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Creates a new pitch 
CREATE PROC [dbo].[newPitch]
@PitchName varchar(35)

AS 
BEGIN TRAN T1
    INSERT INTO PITCH([PitchName])
    VALUES(@PitchName)
IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE    
    COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[newPlayerContractSynth]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[newPlayerContractSynth]
@Run INT 
AS

-- All the params needed to execute the transaction 
DECLARE @Fname1 varchar(35)
DECLARE @Lname1 varchar(35)
DECLARE @DOB2 date
DECLARE @TeamName varchar(35)
DECLARE @BeginDate1 date 
DECLARE @Salary1 numeric(10, 2)



-- Random variables & IDs to be used to grab information 
DECLARE @PlayerRand INT
DECLARE @TeamRand INT
DECLARE @PlayerID2 INT 
DECLARE @TeamID2 INT
DECLARE @NewContractID INT


-- Random number limiters 
DECLARE @NumPlayers INT
DECLARE @NumTeam INT

SET @NumPlayers = (SELECT TOP 1 PlayerID FROM PLAYER ORDER BY PlayerID DESC)
SET @NumTeam = (SELECT TOP 1 TeamID FROM TEAM ORDER BY TeamID DESC)


WHILE @Run > 0
    BEGIN 
        SET @PlayerRand = (SELECT CAST(RAND() * @NumPlayers AS INT))
        SET @TeamRand = (SELECT CAST(RAND() * @NumTeam AS INT))


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

        -- Sets all the info needed for the transaction using the randomly generated IDs
        SET @BeginDate1 = (SELECT GETDATE() - CAST(RAND() AS INT) * 7300)
        SET @Fname1 = (SELECT p.PersonFname FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID2)
        SET @Lname1 = (SELECT p.PersonLname FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID2)
        SET @DOB2 = (SELECT p.PersonDOB FROM PERSON p JOIN PLAYER pl ON p.PersonID = pl.PersonID WHERE pl.PlayerID = @PlayerID2)
        SET @TeamName = (SELECT TeamName FROM TEAM WHERE TeamID = @TeamID2)
        --Gets a salary above league minimum that's somewhere between minimum and a 1,600,000.
        SET @Salary1 = CAST(RAND() * 90000 AS INT) + 10000

        EXEC newContract
        @Fname = @Fname1,
        @Lname = @Lname1,
		@DOB1 = @DOB2,
        @TeamName1 = @TeamName,
        @Salary = @Salary1,
        @BeginDate = @BeginDate1,
        @EndDate = null,
		@ContractID = @NewContractID OUTPUT

		SET @Run = @Run - 1
	END
GO
/****** Object:  StoredProcedure [dbo].[newPlayerContractTranSynthetic]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
/****** Object:  StoredProcedure [dbo].[newStadiumType]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[newStadiumType]
@StadiumTypeName varchar(35)

AS 

BEGIN TRAN T1
    INSERT INTO STADIUM_TYPE([StadiumTypeName])
    VALUES(@StadiumTypeName)
IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1

GO
/****** Object:  StoredProcedure [dbo].[newTeamType]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Cretes a new Team Type
CREATE PROC [dbo].[newTeamType] 
@TeamTypeName varchar(35)

AS 
BEGIN TRAN T1
    INSERT INTO TEAM_TYPE([TeamTypeName])
    VALUES(@TeamTypeName)
IF @@ERROR <> 0 
    ROLLBACK TRAN T1
ELSE    
    COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[newTransaction]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[newTransaction]
@TransactionTypeName varchar(35),
@TransactionName varchar(35),
@TransactionDate date, 
@ContractID INT,
--@Fname varchar(35),
--@Lname varchar(35),
--@DOB date, 
@ContractBegDate date

AS

--DECLARE @ContractID INT
--DECLARE @PlayerID INT
DECLARE @TransactionID INT
DECLARE @TransactionTypeID INT

--SET @PlayerID = (SELECT p.PlayerID FROM PLAYER p
--                 JOIN Person per ON per.PersonID = p.PlayerID
--                 WHERE per.PersonFname = @Fname
--                 AND per.PersonLname = @Lname
--				 AND per.PersonDOB = @DOB)

--SET @ContractID = (SELECT TOP 1 ContractID FROM CONTRACT WHERE PlayerID = @PlayerID AND BeginDate = @ContractBegDate)

IF(@ContractID is null)
	BEGIN
		RAISERROR('ContractID is null, please enter a valid value', 12, 1)
		RETURN 
	END

SET @TransactionTypeID = (SELECT TransactionTypeID FROM TRANSACTION_TYPE WHERE TransactionTypeName = @TransactionTypeName)
BEGIN TRAN T1
    INSERT INTO [TRANSACTION]([TransactionName], [TransactionTypeID])
    VALUES(@TransactionName, @TransactionTypeID)
    
    SET @TransactionID = (SELECT SCOPE_IDENTITY())

    INSERT INTO TEAM_PLAYER_TRANSACTION([TeamPlayerTransactionDate], [ContractID], [TransactionID])
    VALUES(@TransactionDate, @ContractID, @TransactionID)
IF @@ERROR <> 0
    ROLLBACK TRAN T1
ELSE 
    COMMIT TRAN T1


GO
/****** Object:  StoredProcedure [dbo].[newTransactionType]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[newTransactionType]
@TransactionTypeName varchar(35)
AS
BEGIN TRAN T1
	INSERT INTO TRANSACTION_TYPE([TransactionTypeName])
	VALUES(@TransactionTypeName)
IF @@ERROR <> 0 
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspAddClause]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspAddClause]
@ClauseName varchar(35)
AS
BEGIN TRAN t1
	INSERT INTO [CLAUSE](ClauseName)
	VALUES(@ClauseName)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspAddContract]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAddContract]
@TeamName varchar(35),
@Fname varchar(35),
@Lname varchar(35),
@DOB Date,
@Salary numeric(9,1),
@Begin Date
AS
DECLARE @TeamID INT
DECLARE @PlayerID INT
DECLARE @PersonID INT

SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamName = @TeamName)
SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @Fname
				AND PersonLname = @Lname AND PersonDOB = @DOB)
SET @PlayerID = (SELECT PlayerID FROM PLAYER WHERE PersonID = @PersonID)

BEGIN TRAN T1 
	INSERT INTO [CONTRACT](BeginDate, TeamID, PlayerID, Salary)
	VALUES(@Begin, @TeamID, @PlayerID, @Salary)
IF @@ERROR <> 0
	ROLLBACK TRAN TI
ELSE
	COMMIT TRAN T1	
GO
/****** Object:  StoredProcedure [dbo].[uspAddContractClause]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspAddContractClause]
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

SET @ContractID = (SELECT TOP 1 ContractID FROM [CONTRACT] WHERE PlayerID = @PlayerID1 and EndDate is null)

SET @ClauseID = (SELECT ClauseID FROM CLAUSE WHERE ClauseName = @ClauseName)

IF (@ContractID is null)
	BEGIN
		RAISERROR('Not a valid contracted player', 12, 1)
		RETURN
	END

/*Insert into Contract_Clause the Contract and Clause*/
BEGIN TRAN T1
	INSERT INTO CONTRACT_CLAUSE(ContractClauseStartDate, ContractID, ClauseID)
	VALUES(@Start, @ContractID, @ClauseID)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1

GO
/****** Object:  StoredProcedure [dbo].[uspAddEmployeeType]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAddEmployeeType]
@EmpTypeName varchar(35),
@EmpTypeDesc varchar(50)
AS
BEGIN TRAN t1
	INSERT INTO EMPLOYEE_TYPE(EmployeeTypeName, EmployeeTypeDesc)
	VALUES(@EmpTypeName, @EmpTypeDesc)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspAddGameType]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAddGameType]
@GameTypeName varchar(35)
AS
BEGIN TRAN T1
	INSERT INTO GAME_TYPE(GameTypeName)
	VALUES(@GameTypeName)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspAddNewEmployee]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAddNewEmployee]
@EmployeeTypeName varchar(35),
@Fname varchar(35),
@Lname varchar(35),
@DOB Date
AS
DECLARE @EmployeeTypeID INT
DECLARE @PersonID INT

SET @EmployeeTypeID = (SELECT EmployeeTypeID FROM EMPLOYEE_TYPE 
						WHERE EmployeeTypeName = @EmployeeTypeName)
SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @Fname
					AND PersonLname = @Lname AND PersonDOB = @DOB)

BEGIN TRAN T1 
	IF @PersonID IS NULL 
	BEGIN
		INSERT INTO PERSON(PersonFname, PersonLname, PersonDOB)
		VALUES(@Fname, @Lname, @DOB)
		SET @PersonID = (SELECT SCOPE_IDENTITY())
	END
	INSERT INTO EMPLOYEE(PersonID, EmployeeTypeID)
	VALUES(@PersonID, @EmployeeTypeID)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspAddTeamOwner]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspAddTeamOwner]
@SharePercent numeric(3,2),
@StartDate Date,
@Fname varchar(35),
@Lname varchar(35),
@DOB DATE,
@TeamName varchar(35)
AS
DECLARE @TeamID INT
DECLARE @OwnerID INT
DECLARE @PersonID INT

SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamName = @TeamName)
SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @Fname
					AND PersonLname = @Lname
					AND PersonDOB = @DOB)
SET @OwnerID = (SELECT OwnerID FROM [OWNER] WHERE PersonID = @PersonID)

BEGIN TRAN T1 
	IF @PersonID IS NULL
	BEGIN
		INSERT INTO PERSON(PersonFname, PersonLname, PersonDOB)
		VALUES(@Fname, @Lname, @DOB)
		SET @PersonID = (SELECT SCOPE_IDENTITY())
		INSERT INTO [OWNER](PersonID)
		VALUES(@PersonID)
		SET @OwnerID = (SELECT SCOPE_IDENTITY())
	END
	INSERT INTO TEAM_OWNER(SharePercent, StartDate, OwnerID, TeamID)
	VALUES(@SharePercent, @StartDate, @OwnerID, @TeamID)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE 
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspAddTeamWithGame]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAddTeamWithGame]
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
GO
/****** Object:  StoredProcedure [dbo].[uspAssignEmployeeTeam]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspAssignEmployeeTeam]
@Fname1 varchar(35),
@Lname1 varchar(35),
@DOB1 date,
@TeamName1 varchar(35),
@EmployeeTypeName1 varchar(35)
AS
DECLARE @TeamID1 INT
EXEC getTeamID
@TeamName = @TeamName1,
@TeamID = @TeamID1 OUT 

DECLARE @EmployeeID1 INT
EXEC getEmployeeIDForTeamEmployee
@Fname = @Fname1,
@Lname = @Lname1,
@DOB = @DOB1,
@EmployeeTypeName = @EmployeeTypeName1,
@EmployeeID = @EmployeeID1 OUT

IF @TeamID1 IS NULL
 BEGIN
  RAISERROR ('TeamID cannot be NULL; please check all input values', 12,1)
  RETURN
 END;

IF @EmployeeID1 IS NULL
 BEGIN
  RAISERROR ('EmployeeID cannot be NULL; please check all input values', 12,1)
  RETURN
 END

BEGIN TRAN T1
INSERT INTO TEAM_EMPLOYEE (EmployeeID, TeamID)
VALUES (@EmployeeID1, @TeamID1)
IF @@error <> 0
 ROLLBACK TRAN G1
ELSE
 COMMIT TRAN G1
GO
/****** Object:  StoredProcedure [dbo].[uspCreateNewPlayer]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspCreateNewPlayer]
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
GO
/****** Object:  StoredProcedure [dbo].[uspDeletePlayer]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspDeletePlayer]
@Fname varchar(35),
@Lname varchar(35),
@DOB1 varchar(35)
AS
DECLARE @PlayerID1 INT

EXEC [dbo].[getPlayerID] 
@PlayerFname = @Fname,
@PlayerLname = @Lname,
@DOB = @DOB1,
@PlayerID = @PlayerID1 OUTPUT

BEGIN TRAN T1
	DELETE FROM dbo.PLAYER
	WHERE PlayerID = @PlayerID1
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspGetPlayerID]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetPlayerID]
@Fname varchar(35),
@Lname varchar(35),
@DOB DATE,
@PlayerID INT OUTPUT
AS
BEGIN
	SET @PlayerID = (SELECT TOP 1 P.PlayerID 
		FROM PLAYER P 
			JOIN PERSON PE ON P.PersonID = PE.PersonID
		WHERE PE.PersonFname = @Fname 
			AND PE.PersonLname = @Lname 
			AND PE.PersonDOB = @DOB)
END

GO
/****** Object:  StoredProcedure [dbo].[uspGetStatID]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetStatID]
@StatName varchar(35),
@StatAbbrev varchar(35),
@StatID INT OUTPUT
AS
BEGIN
	SET @StatID = (
		SELECT StatID
		FROM [STATS]
		WHERE StatName = @StatName
			AND StatAbbrev = @StatAbbrev)
END
GO
/****** Object:  StoredProcedure [dbo].[uspGetTeamID]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspGetTeamID]
@TeamName varchar(35),
@TeamID INT OUTPUT
AS
SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamName = @TeamName)

GO
/****** Object:  StoredProcedure [dbo].[uspInsertNewPlayerStat]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspInsertNewPlayerStat]
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
GO
/****** Object:  StoredProcedure [dbo].[uspNewAgent]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspNewAgent]
@AgentName varchar(35),
@AgentDesc varchar(50)
AS
BEGIN TRAN T1
	INSERT INTO AGENT(AgentName, AgentDesc)
	VALUES(@AgentName, @AgentName)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspNewGameTeam]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspNewGameTeam]
@TeamName varchar(35),
@GameTeamHAName varchar(35),
@HomeScore INT,
@AwayScore INT,
@GameDate DATE,
@GameTypeName varchar(35)
AS
DECLARE @TeamID INT
DECLARE @GameID INT
DECLARE @GameTeamHAID INT
DECLARE @GameTypeID INT

SET @GameTypeID = (SELECT GameTypeID FROM GAME_TYPE WHERE GameTypeName = @GameTypeName)
SET @TeamID = (SELECT TeamID FROM TEAM WHERE TeamName = @TeamName)
SET @GameID = (SELECT GameID FROM GAME 
				WHERE GameDate = @GameDate
				AND HomeScore = @HomeScore
				AND AwayScore = @AwayScore)
SET @GameTeamHAID = (SELECT GameTeamHAID FROM GAME_TEAM_HA
					WHERE GameTeamHAName = @GameTeamHAName)

BEGIN TRAN T1
	IF @GameID IS NULL
	BEGIN
		INSERT INTO GAME(HomeScore, AwayScore, GameDate, GameTypeID)
		VALUES(@HomeScore, @AwayScore, @GameDate, @GameTypeID)
		SET @GameID = (SELECT SCOPE_IDENTITY())
	END
	INSERT INTO GAME_TEAM(GameID, TeamID, GameTeamHAID)
	VALUES(@GameID, @TeamID, @GameTeamHAID)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspNewPerson]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspNewPerson]
@PersonFname varchar(35),
@PersonLname varchar(35),
@PersonDOB Date,
@PersonEmail varchar(35)
AS
BEGIN TRAN T1
	INSERT INTO PERSON(PersonFname, PersonLname, PersonDOB, Email)
	VALUES(@PersonFname, @PersonLname, @PersonDOB, @PersonEmail)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1

GO
/****** Object:  StoredProcedure [dbo].[uspNewPlayer]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspNewPlayer]
@Fname varchar(30),
@Lname varchar(30),
@DOB DATE,
@PlayerTypeName varchar(30),
@Nickname varchar(30)
AS
DECLARE @PersonID INT
DECLARE @PlayerTypeID INT

SET @PersonID = (SELECT PersonID FROM PERSON 
				WHERE PersonFname = @Fname
				AND PersonLname = @Lname
				AND	PersonDOB = @DOB)
SET @PlayerTypeID = (SELECT PlayerTypeID FROM PLAYER_TYPE
					WHERE PlayerTypeName = @PlayerTypeName)
				
BEGIN TRAN T1
	IF (@PersonID IS NULL)
		BEGIN
			INSERT INTO PERSON(PersonFname, PersonLname, PersonDOB)
			VALUES(@Fname, @Lname, @DOB)
			SET @PersonID = (SELECT SCOPE_IDENTITY())
		END
	INSERT INTO PLAYER(PlayerTypeID, PersonID, PlayerNickName)
	VALUES(@PlayerTypeID, @PersonID, @Nickname)

IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspNewPlayerAgent]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspNewPlayerAgent]
@PlayerFName varchar(35),
@PlayerLName varchar(35),
@PlayerDOB varchar(35),
@AgentName varchar(35),
@BeginDate date
AS
DECLARE @AgentID INT
DECLARE @PlayerID INT
SET @AgentID = (SELECT AgentID FROM AGENT WHERE AgentName = @AgentName)
SET @PlayerID = (SELECT TOP 1 P.PlayerID FROM PLAYER P JOIN PERSON PE ON P.PersonID = PE.PersonID WHERE PE.PersonFname = @PlayerFName AND PE.PersonLname = @PlayerLName AND PE.PersonDOB = @PlayerDOB)
BEGIN TRAN T1
	INSERT INTO PLAYER_AGENT(PlayerID, AgentID, BeginDate)
	VALUES(@PlayerID, @AgentID, @BeginDate)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspNewPlayerType]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspNewPlayerType]
@PlayerTypeName varchar(35)
AS
BEGIN TRAN T1
	INSERT INTO PLAYER_TYPE (PlayerTypeName)
	VALUES(@PlayerTypeName)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1

GO
/****** Object:  StoredProcedure [dbo].[uspNewStat]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspNewStat]
@StatName varchar(35),
@StatAbbrev varchar(35)
AS
BEGIN TRAN T1
	INSERT INTO [STATS](StatName, StatAbbrev)
	VALUES (@StatName, @StatAbbrev)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspNewTeamEmployee]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspNewTeamEmployee]
@Fname varchar(35),
@Lname varchar(35),
@DOB Date,
@EmployeeTypeName varchar(35),
@TeamName varchar(35)
AS
DECLARE @PersonID INT
DECLARE @EmployeeID INT
DECLARE @EmployeeTypeID INT
DECLARE @TeamID INT

SET @PersonID = (SELECT PersonID FROM PERSON WHERE PersonFname = @Fname
					AND PersonLname = @Lname
					AND PersonDOB = @DOB)
SET @EmployeeTypeID = (SELECT EmployeeTypeID FROM EMPLOYEE_TYPE
						WHERE EmployeeTypeName = @EmployeeTypeName)
SET @TeamID = (SELECT TeamID FROM TEAM
				WHERE TeamName = @TeamName)

BEGIN TRAN T1 
	IF @PersonID IS NULL
	BEGIN 
		INSERT INTO PERSON(PersonFname, PersonLname, PersonDOB)
		VALUES(@Fname, @Lname, @DOB)
		SET @PersonID = (SELECT SCOPE_IDENTITY())
	END
	IF @EmployeeID IS NULL 
	BEGIN
		INSERT INTO EMPLOYEE(PersonID, EmployeeTypeID)
		VALUES(@PersonID, @EmployeeTypeID)
		SET @EmployeeID = (SELECT SCOPE_IDENTITY())
	END
	INSERT INTO TEAM_EMPLOYEE(EmployeeID, TeamID)
	VALUES(@EmployeeID, @TeamID)
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
/****** Object:  StoredProcedure [dbo].[uspStartupSyntheticPlayerAgent]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspStartupSyntheticPlayerAgent]
AS
DECLARE @Run INT
DECLARE @Stop INT
SET @Run = 12
SET @Stop = (SELECT COUNT(*) FROM PLAYER) + 1

DECLARE @AgentRand INT
DECLARE @SynthAgentID INT
DECLARE @AgentID INT
DECLARE @SynthBeginDate Date

DECLARE @SynthPlayerFname varchar(35)
DECLARE @SynthPlayerLname varchar(35)
DECLARE @SynthPlayerDOB date
DECLARE @SynthAgent varchar(35)
WHILE @Run < @Stop
BEGIN
IF ((SELECT PlayerID FROM PLAYER WHERE PlayerID = @Run) IS NOT NULL)
	BEGIN
		SET @AgentRand = (SELECT CAST(RAND() * (SELECT COUNT(*) FROM AGENT) AS INT))
		SET @AgentID = (
			CASE
				WHEN (@AgentRand = 0) THEN 1
				ELSE @AgentRand
			END)
		SET @SynthPlayerFname = (SELECT PE.PersonFname FROM PERSON PE JOIN PLAYER P ON PE.PersonID = P.PersonID WHERE P.PlayerID = @Run)
		SET @SynthPlayerLname = (SELECT PE.PersonLname FROM PERSON PE JOIN PLAYER P ON PE.PersonID = P.PersonID WHERE P.PlayerID = @Run)
		SET @SynthPlayerDOB = (SELECT PE.PersonDOB FROM PERSON PE JOIN PLAYER P ON PE.PersonID = P.PersonID WHERE P.PlayerID = @Run)
		SET @SynthAgent = (SELECT AgentName FROM AGENT WHERE AgentID = @AgentID)
		SET @SynthBeginDate = (SELECT GETDATE() - CAST(RAND() * 365 AS INT))

		EXEC uspNewPlayerAgent
		@PlayerFName = @SynthPlayerFname,
		@PlayerLName = @SynthPlayerLname,
		@PlayerDOB = @SynthPlayerDOB,
		@AgentName = @SynthAgent,
		@BeginDate = @SynthBeginDate

		SET @Run = @Run + 1
	END
ELSE
	SET @Run = @Run + 1
END
GO
/****** Object:  StoredProcedure [dbo].[uspSyntheticContractClause]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSyntheticContractClause]
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


GO
/****** Object:  StoredProcedure [dbo].[uspSyntheticEmployee]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspSyntheticEmployee]
@Run INT
AS
DECLARE @Rand INT
DECLARE @PersonID INT
DECLARE @SynthFname varchar(35)
DECLARE @SynthLname varchar(35)
DECLARE @SynthDOB varchar(35)
DECLARE @EmpTypeName varchar(35)
DECLARE @Rnd INT
WHILE @Run > 0
BEGIN
	SET @Rand = (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM CUSTOMER_BUILD.dbo.tblCUSTOMER) AS INT)))
	SET @PersonID = (
		CASE
			WHEN (@Rand = 0) THEN 1
			ELSE @Rand
		END)
	SET @EmpTypeName = (SELECT EmployeeTypeName FROM EMPLOYEE_TYPE WHERE EmployeeTypeID = (SELECT CAST ((RAND()*(6)+1) AS INT)))
	SET @SynthFname = (SELECT CustomerFname FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)
	SET @SynthLname = (SELECT CustomerLname FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)
	SET @SynthDOB = (SELECT DateOfBirth FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)

	EXEC uspAddNewEmployee
	@EmployeeTypeName = @EmpTypeName,
	@Fname = @SynthFname,
	@Lname = @SynthLname,
	@DOB = @SynthDOB

	SET @Run = @Run - 1
END

GO
/****** Object:  StoredProcedure [dbo].[uspSyntheticGameWithTeams]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSyntheticGameWithTeams]
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
SET @Team1 = (SELECT TeamName FROM TEAM WHERE TeamID = 
			(SELECT(CAST ((SELECT RAND())*(SELECT TOP 1 TeamID FROM TEAM ORDER BY TeamID DESC) + 1 AS INT))))

SET @Team2 = (SELECT TeamName FROM TEAM WHERE TeamID = 
			(SELECT(CAST ((SELECT RAND())*(SELECT TOP 1 TeamID FROM TEAM ORDER BY TeamID DESC) + 1 AS INT))))

---- Grab a random HOME_AWAY structure
--SET @HAName = (SELECT GameTeamHAName FROM GAME_TEAM_HA WHERE GameTeamHAID = 
--			(SELECT(CAST ((SELECT RAND())*(2) + 1 AS INT))))

-- Grab a random GAME_TYPE
SET @GameTypeName1 = (SELECT GameTypeName FROM GAME_TYPE WHERE GameTypeID = 
			(SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM GAME_TYPE) + 1 AS INT))))

	EXEC uspAddTeamWithGame
		@TeamName1 = @Team1,
		@TeamName2 = @Team2,
		@HomeScore = @Home,
		@AwayScore = @Away,
		@GameDate = @Date,
		@GameTypeName = @GameTypeName1

	SET @RUN = @RUN - 1
END

GO
/****** Object:  StoredProcedure [dbo].[uspSyntheticNewPlayer]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspSyntheticNewPlayer]
@Run INT
AS
DECLARE @SynthPersonFname varchar(35)
DECLARE @SynthPersonLname varchar(35)
DECLARE @SynthDOB date
DECLARE @SynthPlayerType varchar(35)
DECLARE @PersonRand INT
DECLARE @PersonID INT
DECLARE @PTRand INT
DECLARE @PlayerTypeID INT
WHILE @Run > 0
BEGIN
	SET @PersonRand = (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM PERSON) AS INT)))
	SET @PTRand = (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM PLAYER_TYPE) AS INT)))
	SET @PersonID = (
		CASE
			WHEN (@PersonRand = 0) THEN 1
			ELSE @PersonRand
		END)
	SET @PlayerTypeID = (
		CASE
			WHEN (@PTRand = 0) THEN 1
			ELSE @PTRand
		END)
	SET @SynthPlayerType = (SELECT PlayerTypeName FROM PLAYER_TYPE WHERE PlayerTypeID = @PlayerTypeID)
	SET @SynthPersonFname = (SELECT PersonFname FROM PERSON WHERE PersonID = @PersonID)
	SET @SynthPersonLname = (SELECT PersonLname FROM PERSON WHERE PersonID = @PersonID)
	SET @SynthDOB = (SELECT PersonDOB FROM PERSON WHERE PersonID = @PersonID)

	EXEC uspCreateNewPlayer
	@PlayerFname = @SynthPersonFname,
	@PlayerLname = @SynthPersonLname,
	@PlayerDOB = @SynthDOB,
	@PlayerType = @SynthPlayerType

	SET @Run = @Run - 1
END

GO
/****** Object:  StoredProcedure [dbo].[uspSyntheticNewPlayerStats]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSyntheticNewPlayerStats]
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
/****** Object:  StoredProcedure [dbo].[uspSyntheticPerson]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspSyntheticPerson]
@Run INT
AS
DECLARE @Rand INT
DECLARE @PersonID INT
DECLARE @SynthFname varchar(35)
DECLARE @SynthLname varchar(35)
DECLARE @SynthDOB varchar(35)
DECLARE @SynthEmail varchar(35)
WHILE @Run > 0
BEGIN
	SET @Rand = (SELECT(CAST ((SELECT RAND())*(SELECT COUNT(*) FROM CUSTOMER_BUILD.dbo.tblCUSTOMER) AS INT)))
	SET @PersonID = (
		CASE
			WHEN (@Rand = 0) THEN 1
			ELSE @Rand
		END)
	SET @SynthFname = (SELECT CustomerFname FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)
	SET @SynthLname = (SELECT CustomerLname FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)
	SET @SynthDOB = (SELECT DateOfBirth FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)
	SET @SynthEmail = (SELECT Email FROM CUSTOMER_BUILD.dbo.tblCUSTOMER WHERE CustomerID = @PersonID)

	EXEC uspNewPerson
	@PersonFname = @SynthFname,
	@PersonLname = @SynthLname,
	@PersonDOB = @SynthDOB,
	@PersonEmail = @SynthEmail

	SET @Run = @Run - 1
END

GO
/****** Object:  StoredProcedure [dbo].[uspSyntheticTeamEmployee]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[uspSyntheticTeamEmployee]
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




GO
/****** Object:  StoredProcedure [dbo].[uspUpdateNickName]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspUpdateNickName]
@Fname varchar(30),
@Lname varchar(30),
@DOB DATE,
@Nickname varchar(30)
AS
DECLARE @PlayerID INT

SET @PlayerID = (SELECT TOP 1 PlayerID FROM PLAYER pl 
				JOIN PERSON p on pl.PersonID = p.PersonID
				WHERE p.PersonFname = @Fname
				AND p.PersonLname = @Lname
				AND p.PersonDOB = @DOB)

BEGIN TRAN T1
	UPDATE PLAYER 
	SET PlayerNickName = @Nickname
	WHERE PlayerID = @PlayerID
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1

GO
/****** Object:  StoredProcedure [dbo].[uspUpdatePlayerNickName]    Script Date: 3/19/2017 7:20:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[uspUpdatePlayerNickName]
@Fname varchar(35),
@Lname varchar(35),
@DOB1 Date,
@PlayerNickName varchar(35)
AS
DECLARE @PlayerID1 INT

EXEC [dbo].[getPlayerID] 
@PlayerFname = @Fname,
@PlayerLname = @Lname,
@DOB = @DOB1,
@PlayerID = @PlayerID1 OUTPUT

BEGIN TRAN T1
	UPDATE PLAYER
	SET PlayerNickName = @PlayerNickName
	WHERE PlayerID = @PlayerID1
IF @@ERROR <> 0
	ROLLBACK TRAN T1
ELSE
	COMMIT TRAN T1
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[20] 2[33] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = -144
         Left = 0
      End
      Begin Tables = 
         Begin Table = "t"
            Begin Extent = 
               Top = 9
               Left = 57
               Bottom = 206
               Right = 348
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 207
               Left = 57
               Bottom = 404
               Right = 295
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 405
               Left = 57
               Bottom = 602
               Right = 305
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "per"
            Begin Extent = 
               Top = 603
               Left = 57
               Bottom = 800
               Right = 295
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TeamRosters'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'TeamRosters'
GO
USE [master]
GO
ALTER DATABASE [MLS] SET  READ_WRITE 
GO
