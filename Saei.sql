-- In SSMS, select the Saei database and run this file.
IF DB_NAME() <> 'Saei'
    THROW 51000, 'Select the Saei database first.', 1;

-- Skip setup when the database already has its tables.
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
    RETURN;

-- Required by SQL Server for the filtered unique indexes.
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT ON;
SET QUOTED_IDENTIFIER, CONCAT_NULL_YIELDS_NULL, XACT_ABORT ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRANSACTION;

CREATE TABLE dbo.Users (
    UserId INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    FullName NVARCHAR(150) NOT NULL,
    Email NVARCHAR(254) NOT NULL,
    PasswordHash VARCHAR(512) NULL,
    Phone NVARCHAR(30) NULL,
    Role VARCHAR(10) NOT NULL DEFAULT 'member',
    CHECK(Role IN ('member','company','admin')),
    IsActive BIT NOT NULL DEFAULT 1,
    EmailVerifiedAt DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    DeletedAt DATETIME NULL,
    ProfessionalTitle NVARCHAR(150) NULL,
    Bio NVARCHAR(3000) NULL,
    City NVARCHAR(100) NULL,
    CountryCode CHAR(2) NULL,
    Availability VARCHAR(20) NOT NULL DEFAULT 'available',
    AvatarFileId INT NULL,
    AvatarFileKind VARCHAR(12) NOT NULL DEFAULT 'image',
    PortfolioUrl NVARCHAR(1000) NULL,
    LinkedInUrl NVARCHAR(1000) NULL,
    ExperienceSummary NVARCHAR(4000) NULL,
    IsPublic BIT NOT NULL DEFAULT 1,
    Theme VARCHAR(8) NOT NULL DEFAULT 'light',
    CHECK(AvatarFileKind='image'),
    CHECK(Availability IN ('available','busy','unavailable')),
    CHECK(Theme IN ('light','dark','system')),
    UNIQUE (Email),
    CHECK(LEN(LTRIM(RTRIM(FullName))) >= 2),
    CHECK(Email LIKE N'%_@_%._%')
);
CREATE TABLE dbo.Files (
    FileId INT IDENTITY NOT NULL PRIMARY KEY,
    UploadedByUserId INT NOT NULL,
    OriginalName NVARCHAR(255) NOT NULL,
    StorageKey NVARCHAR(450) NOT NULL UNIQUE,
    FileKind VARCHAR(12) NOT NULL,
    MimeType VARCHAR(100) NOT NULL,
    SizeBytes INT NOT NULL,
    Sha256 binary(32) NULL,
    ScanStatus VARCHAR(12) NOT NULL DEFAULT 'pending',
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    DeletedAt DATETIME NULL,
    UNIQUE(FileId,FileKind),
    FOREIGN KEY(UploadedByUserId) REFERENCES dbo.Users(UserId),
    CHECK(SizeBytes BETWEEN 1 AND 10485760),
    CHECK(ScanStatus IN ('pending','clean','rejected')),
    CHECK(
       (FileKind='image' AND MimeType IN ('image/png','image/jpeg','image/webp')) OR
       (FileKind='pdf' AND MimeType='application/pdf') OR
       (FileKind='document' AND MimeType IN ('application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document')))
);
ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Avatar
    FOREIGN KEY(AvatarFileId,AvatarFileKind) REFERENCES dbo.Files(FileId,FileKind);

CREATE TABLE dbo.Skills (
    SkillId INT IDENTITY NOT NULL PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE
);
CREATE TABLE dbo.UserSkills (
    UserId INT NOT NULL,
    SkillId INT NOT NULL,
    PRIMARY KEY(UserId,SkillId),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(SkillId) REFERENCES dbo.Skills(SkillId)
);
CREATE TABLE dbo.Companies (
    OwnerUserId INT NOT NULL,
    FOREIGN KEY(OwnerUserId) REFERENCES dbo.Users(UserId),
    CompanyId INT IDENTITY NOT NULL PRIMARY KEY,
    Name NVARCHAR(200) NOT NULL,
    Slug VARCHAR(180) NOT NULL UNIQUE,
    Description NVARCHAR(4000) NULL,
    WebsiteUrl NVARCHAR(1000) NULL,
    ContactEmail NVARCHAR(254) NULL,
    City NVARCHAR(100) NULL,
    CountryCode CHAR(2) NULL,
    LogoFileId INT NULL,
    LogoFileKind VARCHAR(12) NOT NULL DEFAULT 'image',
    Status VARCHAR(16) NOT NULL DEFAULT 'pending',
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    DeletedAt DATETIME NULL,
    CHECK(LogoFileKind='image'),
    FOREIGN KEY(LogoFileId,LogoFileKind) REFERENCES dbo.Files(FileId,FileKind),
    CHECK(Status IN ('pending','active','suspended'))
);
CREATE TABLE dbo.Listings (
    ListingId INT IDENTITY NOT NULL PRIMARY KEY,
    LegacyKey NVARCHAR(100) NULL,
    ListingType VARCHAR(16) NOT NULL,
    PublisherUserId INT NOT NULL,
    CompanyId INT NULL,
    CategoryCode VARCHAR(50) NOT NULL,
    DetailsJson NVARCHAR(max) NOT NULL DEFAULT N'[]',
    Title NVARCHAR(250) NOT NULL,
    Description NVARCHAR(max) NOT NULL,
    Status VARCHAR(16) NOT NULL DEFAULT 'draft',
    LocationMode VARCHAR(12) NOT NULL DEFAULT 'remote',
    City NVARCHAR(100) NULL,
    CountryCode CHAR(2) NULL,
    PublishedAt DATETIME NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    DeletedAt DATETIME NULL,
    BudgetMin DECIMAL(19,3) NULL,
    BudgetMax DECIMAL(19,3) NULL,
    CurrencyCode CHAR(3) NULL DEFAULT 'JOD',
    DurationDays INT NULL,
    ProjectType VARCHAR(12) NULL,
    ApplicationDeadline DATETIME NULL,
    EmploymentType VARCHAR(16) NULL,
    ExperienceLevel VARCHAR(12) NULL,
    SalaryMin DECIMAL(19,3) NULL,
    SalaryMax DECIMAL(19,3) NULL,
    SalaryPeriod VARCHAR(12) NULL,
    DurationMonths INT NULL,
    MonthlyStipend DECIMAL(19,3) NULL,
    Capacity INT NULL,
    InstructorUserId INT NULL,
    InstructorName NVARCHAR(150) NULL,
    LevelCode VARCHAR(16) NULL,
    Price DECIMAL(19,3) NULL,
    DurationMinutes INT NULL,
    PracticalProject NVARCHAR(2000) NULL,
    PresenterName NVARCHAR(150) NULL,
    StartsAt DATETIME NULL,
    EndsAt DATETIME NULL,
    TimeZoneId VARCHAR(60) NULL,
    Venue NVARCHAR(250) NULL,
    MeetingUrl NVARCHAR(1000) NULL,
    EventType VARCHAR(16) NULL,
    CoverFileId INT NULL,
    CoverFileKind VARCHAR(12) NOT NULL DEFAULT 'image',
    DetailsPdfFileId INT NULL,
    DetailsPdfFileKind VARCHAR(12) NOT NULL DEFAULT 'pdf',
    CHECK(CoverFileKind='image' AND DetailsPdfFileKind='pdf'),
    FOREIGN KEY(CoverFileId,CoverFileKind) REFERENCES dbo.Files(FileId,FileKind),
    FOREIGN KEY(DetailsPdfFileId,DetailsPdfFileKind) REFERENCES dbo.Files(FileId,FileKind),
    CHECK(CurrencyCode='JOD'),
    FOREIGN KEY(InstructorUserId) REFERENCES dbo.Users(UserId),
    CHECK(ListingType <> 'project' OR (BudgetMin>=0 AND BudgetMax>=BudgetMin)),
    CHECK(ListingType <> 'project' OR (DurationDays>0)),
    CHECK(ListingType <> 'project' OR (ProjectType IN ('fixed','ongoing'))),
    CHECK(ListingType <> 'job' OR (EmploymentType IN ('full-time','part-time','contract'))),
    CHECK(ListingType <> 'job' OR (ExperienceLevel IN ('junior','mid','senior'))),
    CHECK(ListingType <> 'job' OR ((SalaryMin IS NULL AND SalaryMax IS NULL) OR (SalaryMin IS NOT NULL AND SalaryMax IS NOT NULL AND SalaryMin>=0 AND SalaryMax>=SalaryMin))),
    CHECK(ListingType <> 'job' OR (SalaryPeriod IN ('hour','month','year'))),
    CHECK(ListingType <> 'internship' OR (DurationMonths BETWEEN 1 AND 36)),
    CHECK(ListingType <> 'internship' OR (MonthlyStipend>=0)),
    CHECK(ListingType <> 'internship' OR (Capacity>0)),
    CHECK(ListingType <> 'course' OR (LevelCode IN ('beginner','intermediate','advanced'))),
    CHECK(ListingType <> 'course' OR (Price>=0)),
    CHECK(ListingType <> 'course' OR (DurationMinutes>0)),
    CHECK(ListingType <> 'workshop' OR (LevelCode IN ('beginner','intermediate','advanced'))),
    CHECK(ListingType <> 'workshop' OR (EndsAt>StartsAt)),
    CHECK(ListingType <> 'workshop' OR (Capacity>0)),
    CHECK(ListingType <> 'workshop' OR (Price>=0)),
    CHECK(ListingType <> 'event' OR (EventType IN ('meetup','talk','conference'))),
    CHECK(ListingType <> 'event' OR (EndsAt>StartsAt)),
    CHECK(ListingType <> 'event' OR (Capacity>0)),
    CHECK(ListingType <> 'event' OR (Price>=0)),
    CHECK(Status IN ('draft','pending','rejected') OR
        (ListingType = 'project' AND BudgetMin IS NOT NULL AND BudgetMax IS NOT NULL AND CurrencyCode IS NOT NULL AND DurationDays IS NOT NULL AND ProjectType IS NOT NULL) OR
        (ListingType = 'job' AND EmploymentType IS NOT NULL AND ExperienceLevel IS NOT NULL AND CurrencyCode IS NOT NULL AND SalaryPeriod IS NOT NULL) OR
        (ListingType = 'internship' AND DurationMonths IS NOT NULL AND MonthlyStipend IS NOT NULL AND CurrencyCode IS NOT NULL) OR
        (ListingType = 'course' AND InstructorName IS NOT NULL AND LevelCode IS NOT NULL AND Price IS NOT NULL AND CurrencyCode IS NOT NULL AND DurationMinutes IS NOT NULL) OR
        (ListingType = 'workshop' AND PresenterName IS NOT NULL AND LevelCode IS NOT NULL AND StartsAt IS NOT NULL AND EndsAt IS NOT NULL AND TimeZoneId IS NOT NULL AND Capacity IS NOT NULL AND Price IS NOT NULL AND CurrencyCode IS NOT NULL) OR
        (ListingType = 'event' AND EventType IS NOT NULL AND StartsAt IS NOT NULL AND EndsAt IS NOT NULL AND TimeZoneId IS NOT NULL AND Venue IS NOT NULL AND Capacity IS NOT NULL AND Price IS NOT NULL AND CurrencyCode IS NOT NULL)),
    UNIQUE(ListingId,ListingType),
    FOREIGN KEY(PublisherUserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(CompanyId) REFERENCES dbo.Companies(CompanyId),
    CHECK(CategoryCode IN ('development','design','marketing','career')),
    CHECK(ListingType IN ('project','job','internship','course','workshop','event')),
    CHECK((ListingType IN ('job','internship') AND CompanyId IS NOT NULL) OR (ListingType NOT IN ('job','internship') AND CompanyId IS NULL)),
    CHECK(Status IN ('draft','pending','published','paused','closed','rejected','archived')),
    CHECK(Status<>'published' OR PublishedAt IS NOT NULL),
    CHECK(LocationMode IN ('remote','onsite','hybrid')),
    CHECK(LEN(LTRIM(RTRIM(Title)))>0)
);
CREATE UNIQUE INDEX UX_Listings_LegacyKey ON dbo.Listings(ListingType,LegacyKey) WHERE LegacyKey IS NOT NULL;
CREATE INDEX IX_Listings_Discovery ON dbo.Listings(ListingType,Status,CategoryCode,PublishedAt DESC) INCLUDE(Title,PublisherUserId,CompanyId) WHERE DeletedAt IS NULL;
CREATE INDEX IX_Listings_Publisher ON dbo.Listings(PublisherUserId,CreatedAt DESC);
CREATE INDEX IX_Listings_Company ON dbo.Listings(CompanyId,Status) WHERE CompanyId IS NOT NULL;
CREATE TABLE dbo.ListingSkills (
    ListingId INT NOT NULL,
    SkillId INT NOT NULL,
    PRIMARY KEY(ListingId,SkillId),
    FOREIGN KEY(ListingId) REFERENCES dbo.Listings(ListingId),
    FOREIGN KEY(SkillId) REFERENCES dbo.Skills(SkillId)
);
CREATE TABLE dbo.Applications (
    ApplicationId INT IDENTITY NOT NULL PRIMARY KEY,
    ListingId INT NOT NULL,
    ListingType VARCHAR(16) NOT NULL,
    ApplicantUserId INT NOT NULL,
    FullNameSnapshot NVARCHAR(150) NOT NULL,
    EmailSnapshot NVARCHAR(254) NOT NULL,
    PhoneSnapshot NVARCHAR(30) NULL,
    LocationSnapshot NVARCHAR(200) NULL,
    ExperienceYears DECIMAL(4,1) NULL,
    CoverLetter NVARCHAR(4000) NOT NULL,
    PortfolioUrl NVARCHAR(1000) NULL,
    ResumeFileId INT NULL,
    ResumeFileKind VARCHAR(12) NOT NULL DEFAULT 'pdf',
    ProposedAmount DECIMAL(19,3) NULL,
    CurrencyCode CHAR(3) NULL,
    Status VARCHAR(16) NOT NULL DEFAULT 'pending',
    ReviewedByUserId INT NULL,
    ReviewedAt DATETIME NULL,
    SubmittedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    UNIQUE(ApplicantUserId,ListingId),
    CHECK(ListingType IN ('project','job','internship')),
    FOREIGN KEY(ListingId,ListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    FOREIGN KEY(ApplicantUserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(ReviewedByUserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(ResumeFileId,ResumeFileKind) REFERENCES dbo.Files(FileId,FileKind),
    CHECK(CurrencyCode='JOD'),
    CHECK(ResumeFileKind IN ('pdf','document')),
    CHECK(Status IN ('pending','reviewing','accepted','rejected','withdrawn')),
    CHECK(ExperienceYears BETWEEN 0 AND 80),
    CHECK((ProposedAmount IS NULL AND CurrencyCode IS NULL) OR (ListingType='project' AND ProposedAmount IS NOT NULL AND ProposedAmount>=0 AND CurrencyCode IS NOT NULL)),
    CHECK((ReviewedAt IS NULL AND ReviewedByUserId IS NULL) OR (ReviewedAt IS NOT NULL AND ReviewedByUserId IS NOT NULL))
);
CREATE INDEX IX_Applications_ListingStatus ON dbo.Applications(ListingId,Status,SubmittedAt DESC);
CREATE TABLE dbo.Favorites (
    UserId INT NOT NULL,
    ListingId INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    PRIMARY KEY(UserId,ListingId),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(ListingId) REFERENCES dbo.Listings(ListingId)
);
CREATE TABLE dbo.CartItems (
    UserId INT NOT NULL,
    ListingId INT NOT NULL,
    ListingType VARCHAR(16) NOT NULL,
    AddedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    PRIMARY KEY(UserId,ListingId),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(ListingId,ListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    CHECK(ListingType IN ('course','workshop','event','internship'))
);
CREATE TABLE dbo.Orders (
    OrderId INT IDENTITY NOT NULL PRIMARY KEY,
    UserId INT NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT 'JOD',
    Status VARCHAR(16) NOT NULL DEFAULT 'pending',
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    PaidAt DATETIME NULL,
    UNIQUE(OrderId,CurrencyCode),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    CHECK(CurrencyCode='JOD'),
    CHECK(Status IN ('pending','paid','cancelled','refunded')),
    CHECK(Status NOT IN ('paid','refunded') OR PaidAt IS NOT NULL)
);
CREATE INDEX IX_Orders_User ON dbo.Orders(UserId,CreatedAt DESC);
CREATE TABLE dbo.OrderItems (
    OrderItemId INT IDENTITY NOT NULL PRIMARY KEY,
    OrderId INT NOT NULL,
    ListingId INT NOT NULL,
    ListingType VARCHAR(16) NOT NULL,
    TitleSnapshot NVARCHAR(250) NOT NULL,
    UnitPrice DECIMAL(19,3) NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT 'JOD',
    UNIQUE(OrderId,ListingId),
    UNIQUE(OrderItemId,ListingId),
    FOREIGN KEY(OrderId,CurrencyCode) REFERENCES dbo.Orders(OrderId,CurrencyCode),
    FOREIGN KEY(ListingId,ListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    CHECK(ListingType IN ('course','workshop','event')),
    CHECK(UnitPrice>=0)
);
CREATE TABLE dbo.Payments (
    PaymentId INT IDENTITY NOT NULL PRIMARY KEY,
    OrderId INT NOT NULL,
    CurrencyCode CHAR(3) NOT NULL DEFAULT 'JOD',
    Provider VARCHAR(40) NOT NULL,
    ProviderReference NVARCHAR(150) NULL,
    IdempotencyKey VARCHAR(36) NOT NULL UNIQUE,
    Amount DECIMAL(19,3) NOT NULL,
    Status VARCHAR(16) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    ProcessedAt DATETIME NULL,
    FOREIGN KEY(OrderId,CurrencyCode) REFERENCES dbo.Orders(OrderId,CurrencyCode),
    CHECK(Amount>=0),
    CHECK(Status IN ('pending','succeeded','failed','refunded'))
);
CREATE UNIQUE INDEX UX_Payments_ProviderReference ON dbo.Payments(Provider,ProviderReference) WHERE ProviderReference IS NOT NULL;
CREATE TABLE dbo.CourseEnrollments (
    EnrollmentId INT IDENTITY NOT NULL PRIMARY KEY,
    UserId INT NOT NULL,
    CourseId INT NOT NULL,
    CourseListingType VARCHAR(16) NOT NULL DEFAULT 'course',
    CHECK(CourseListingType='course'),
    OrderItemId INT NULL,
    Status VARCHAR(16) NOT NULL DEFAULT 'active',
    EnrolledAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    CompletedAt DATETIME NULL,
    UNIQUE(UserId,CourseId),
    UNIQUE(EnrollmentId,CourseId),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(CourseId,CourseListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    FOREIGN KEY(OrderItemId,CourseId) REFERENCES dbo.OrderItems(OrderItemId,ListingId),
    CHECK(Status IN ('active','completed','cancelled')),
    CHECK(Status<>'completed' OR CompletedAt IS NOT NULL)
);
CREATE TABLE dbo.CourseContent (
    ContentId INT IDENTITY NOT NULL PRIMARY KEY,
    CourseId INT NOT NULL,
    CourseListingType VARCHAR(16) NOT NULL DEFAULT 'course',
    ContentType VARCHAR(8) NOT NULL DEFAULT 'lesson',
    QuizId INT NULL,
    Title NVARCHAR(250) NULL,
    Body NVARCHAR(max) NULL,
    VideoUrl NVARCHAR(1000) NULL,
    DurationSeconds INT NULL,
    IsPreview BIT NULL,
    Prompt NVARCHAR(2000) NULL,
    ChoicesJson NVARCHAR(max) NULL,
    CorrectChoiceIndex INT NULL,
    Explanation NVARCHAR(2000) NULL,
    Points DECIMAL(8,2) NULL,
    SortOrder INT NOT NULL,
    UNIQUE(ContentId,CourseId,ContentType),
    UNIQUE(ContentId,ContentType),
    UNIQUE(ContentId,QuizId),
    FOREIGN KEY(CourseId,CourseListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    CHECK(CourseListingType='course'),
    CHECK(SortOrder>=0),
    CHECK(
        (ContentType='lesson' AND QuizId IS NULL AND Title IS NOT NULL
            AND (DurationSeconds IS NULL OR DurationSeconds>=0)
            AND Prompt IS NULL AND Explanation IS NULL AND Points IS NULL
            AND ChoicesJson IS NULL AND CorrectChoiceIndex IS NULL)
        OR
        (ContentType='question' AND QuizId IS NOT NULL AND Prompt IS NOT NULL
            AND Points IS NOT NULL AND Points>0
            AND ChoicesJson IS NOT NULL
            AND CorrectChoiceIndex IS NOT NULL AND CorrectChoiceIndex>=0
            AND Title IS NULL AND Body IS NULL
            AND VideoUrl IS NULL AND DurationSeconds IS NULL AND IsPreview IS NULL)
    )
);
CREATE UNIQUE INDEX UX_CourseContent_LessonOrder ON dbo.CourseContent(CourseId,SortOrder) WHERE ContentType='lesson';
CREATE UNIQUE INDEX UX_CourseContent_QuestionOrder ON dbo.CourseContent(QuizId,SortOrder) WHERE ContentType='question';

CREATE TABLE dbo.LessonProgress (
    EnrollmentId INT NOT NULL,
    LessonId INT NOT NULL,
    LessonContentType VARCHAR(8) NOT NULL DEFAULT 'lesson',
    CourseId INT NOT NULL,
    IsCompleted BIT NOT NULL DEFAULT 0,
    PlaybackSeconds INT NOT NULL DEFAULT 0,
    Notes NVARCHAR(3000) NULL,
    UpdatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    PRIMARY KEY(EnrollmentId,LessonId),
    FOREIGN KEY(EnrollmentId,CourseId) REFERENCES dbo.CourseEnrollments(EnrollmentId,CourseId),
    CHECK(LessonContentType='lesson'),
    FOREIGN KEY(LessonId,CourseId,LessonContentType) REFERENCES dbo.CourseContent(ContentId,CourseId,ContentType),
    CHECK(PlaybackSeconds>=0)
);
CREATE TABLE dbo.Registrations (
    RegistrationId INT IDENTITY NOT NULL PRIMARY KEY,
    UserId INT NOT NULL,
    ListingId INT NOT NULL,
    ListingType VARCHAR(16) NOT NULL,
    OrderItemId INT NULL,
    Status VARCHAR(16) NOT NULL DEFAULT 'pending',
    RegisteredAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    AttendedAt DATETIME NULL,
    UNIQUE(UserId,ListingId),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(ListingId,ListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    FOREIGN KEY(OrderItemId,ListingId) REFERENCES dbo.OrderItems(OrderItemId,ListingId),
    CHECK(ListingType IN ('workshop','event')),
    CHECK(Status IN ('pending','confirmed','waitlisted','cancelled','attended')),
    CHECK(Status<>'attended' OR AttendedAt IS NOT NULL)
);
CREATE INDEX IX_Registrations_Listing ON dbo.Registrations(ListingId,Status);
CREATE TABLE dbo.Conversations (
    ConversationId INT IDENTITY NOT NULL PRIMARY KEY,
    Subject NVARCHAR(250) NULL,
    RelatedListingId INT NULL,
    CreatedByUserId INT NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY(RelatedListingId) REFERENCES dbo.Listings(ListingId),
    FOREIGN KEY(CreatedByUserId) REFERENCES dbo.Users(UserId)
);
CREATE TABLE dbo.ConversationParticipants (
    ConversationId INT NOT NULL,
    UserId INT NOT NULL,
    JoinedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    LeftAt DATETIME NULL,
    LastReadAt DATETIME NULL,
    PRIMARY KEY(ConversationId,UserId),
    FOREIGN KEY(ConversationId) REFERENCES dbo.Conversations(ConversationId),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId)
);
CREATE TABLE dbo.Messages (
    MessageId INT IDENTITY NOT NULL PRIMARY KEY,
    ConversationId INT NOT NULL,
    SenderUserId INT NOT NULL,
    Body NVARCHAR(4000) NULL,
    MessageType VARCHAR(12) NOT NULL DEFAULT 'text',
    CallStatus VARCHAR(12) NULL,
    CallDurationSeconds INT NULL,
    SentAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    DeletedAt DATETIME NULL,
    FOREIGN KEY(ConversationId,SenderUserId) REFERENCES dbo.ConversationParticipants(ConversationId,UserId),
    CHECK(
        (MessageType='text' AND Body IS NOT NULL AND LEN(LTRIM(RTRIM(Body)))>0
            AND CallStatus IS NULL AND CallDurationSeconds IS NULL)
        OR (MessageType='video-call' AND Body IS NULL AND CallStatus IS NOT NULL
            AND ((CallStatus='completed' AND CallDurationSeconds IS NOT NULL AND CallDurationSeconds>=0)
                 OR (CallStatus IN ('missed','declined','cancelled') AND CallDurationSeconds IS NULL)))
    )
);
CREATE INDEX IX_Messages_Conversation ON dbo.Messages(ConversationId,SentAt DESC,MessageId DESC);
CREATE TABLE dbo.Attachments (
    AttachmentId INT IDENTITY NOT NULL PRIMARY KEY,
    UserId INT NULL,
    MessageId INT NULL,
    FileId INT NOT NULL,
    FileKind VARCHAR(12) NULL,
    Purpose VARCHAR(20) NOT NULL,
    Caption NVARCHAR(200) NULL,
    IsPrimary BIT NOT NULL DEFAULT 0,
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(MessageId) REFERENCES dbo.Messages(MessageId),
    FOREIGN KEY(FileId) REFERENCES dbo.Files(FileId),
    FOREIGN KEY(FileId,FileKind) REFERENCES dbo.Files(FileId,FileKind),
    CHECK(
        (Purpose='message' AND MessageId IS NOT NULL AND UserId IS NULL AND IsPrimary=0)
        OR (Purpose='resume' AND UserId IS NOT NULL AND MessageId IS NULL
            AND FileKind IS NOT NULL AND FileKind IN ('pdf','document'))
        OR (Purpose='education' AND UserId IS NOT NULL AND MessageId IS NULL
            AND FileKind IS NOT NULL AND FileKind IN ('pdf','image') AND IsPrimary=0)
    )
);
CREATE UNIQUE INDEX UX_Attachments_ProfileFile ON dbo.Attachments(UserId,FileId,Purpose) WHERE UserId IS NOT NULL;
CREATE UNIQUE INDEX UX_Attachments_MessageFile ON dbo.Attachments(MessageId,FileId) WHERE MessageId IS NOT NULL;
CREATE UNIQUE INDEX UX_Attachments_PrimaryResume ON dbo.Attachments(UserId) WHERE IsPrimary=1;

CREATE TABLE dbo.Comments (
    ListingType VARCHAR(16) NOT NULL DEFAULT 'project',
    CHECK(ListingType='project'),
    CommentId INT IDENTITY NOT NULL PRIMARY KEY,
    ListingId INT NOT NULL,
    UserId INT NOT NULL,
    ParentCommentId INT NULL,
    Body NVARCHAR(3000) NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    DeletedAt DATETIME NULL,
    UNIQUE(CommentId,ListingId),
    FOREIGN KEY(ListingId,ListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    FOREIGN KEY(UserId) REFERENCES dbo.Users(UserId),
    FOREIGN KEY(ParentCommentId,ListingId) REFERENCES dbo.Comments(CommentId,ListingId),
    CHECK(ParentCommentId IS NULL OR ParentCommentId<>CommentId),
    CHECK(LEN(LTRIM(RTRIM(Body)))>0)
);
CREATE INDEX IX_Comments_Listing ON dbo.Comments(ListingId,CreatedAt DESC);
CREATE TABLE dbo.AuditLogs (
    AuditLogId INT IDENTITY NOT NULL PRIMARY KEY,
    ActorUserId INT NULL,
    ActionCode VARCHAR(40) NOT NULL,
    EntityName VARCHAR(80) NOT NULL,
    EntityId NVARCHAR(100) NOT NULL,
    Details NVARCHAR(4000) NULL,
    CreatedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    FOREIGN KEY(ActorUserId) REFERENCES dbo.Users(UserId)
);
CREATE INDEX IX_AuditLogs_Entity ON dbo.AuditLogs(EntityName,EntityId,CreatedAt DESC);

CREATE TABLE dbo.CourseQuizzes (
    QuizId INT IDENTITY NOT NULL PRIMARY KEY,
    CourseId INT NOT NULL,
    CourseListingType VARCHAR(16) NOT NULL DEFAULT 'course',
    CHECK(CourseListingType='course'),
    Title NVARCHAR(200) NOT NULL,
    PassingPercent DECIMAL(5,2) NOT NULL DEFAULT 70,
    MaxAttempts INT NOT NULL DEFAULT 3,
    UNIQUE(QuizId,CourseId),
    FOREIGN KEY(CourseId,CourseListingType) REFERENCES dbo.Listings(ListingId,ListingType),
    CHECK(PassingPercent BETWEEN 0 AND 100),
    CHECK(MaxAttempts>0)
 );
 ALTER TABLE dbo.CourseContent ADD CONSTRAINT FK_CourseContent_Quiz
    FOREIGN KEY(QuizId,CourseId) REFERENCES dbo.CourseQuizzes(QuizId,CourseId);
 CREATE TABLE dbo.QuizAttempts (
    AttemptId INT IDENTITY NOT NULL PRIMARY KEY,
    EnrollmentId INT NOT NULL,
    CourseId INT NOT NULL,
    QuizId INT NOT NULL,
    AttemptNumber INT NOT NULL,
    StartedAt DATETIME NOT NULL DEFAULT GETUTCDATE(),
    SubmittedAt DATETIME NULL,
    AnswersJson NVARCHAR(max) NOT NULL DEFAULT N'{}',
    EarnedPoints DECIMAL(10,2) NULL,
    TotalPoints DECIMAL(10,2) NULL,
    UNIQUE(EnrollmentId,QuizId,AttemptNumber),
    UNIQUE(AttemptId,QuizId),
    FOREIGN KEY(EnrollmentId,CourseId) REFERENCES dbo.CourseEnrollments(EnrollmentId,CourseId),
    FOREIGN KEY(QuizId,CourseId) REFERENCES dbo.CourseQuizzes(QuizId,CourseId),
    CHECK(AttemptNumber>0),
    CHECK((SubmittedAt IS NULL AND EarnedPoints IS NULL AND TotalPoints IS NULL) OR (SubmittedAt IS NOT NULL AND EarnedPoints IS NOT NULL AND TotalPoints IS NOT NULL AND TotalPoints>0 AND EarnedPoints BETWEEN 0 AND TotalPoints))
 );

-- Initial skills
INSERT dbo.Skills(Name)
SELECT v.Name FROM (VALUES(N'HTML'),(N'CSS'),(N'JavaScript'),(N'React'),(N'Node.js'),(N'Figma'),(N'UI/UX'),(N'تصميم الهوية البصرية'),(N'التسويق الرقمي'),(N'التواصل'),(N'إدارة المشاريع')) v(Name)
WHERE NOT EXISTS(SELECT 1 FROM dbo.Skills s WHERE s.Name=v.Name);

COMMIT;
