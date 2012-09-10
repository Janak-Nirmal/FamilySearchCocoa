FamilySearchAPI
===============

An easy to use library for interacting with the FamilySearch.org API on iOS or OS X.

### Installation

In your Podfile, add this line:

	pod "FamilySearchAPI"

pod? => https://github.com/CocoaPods/CocoaPods/

### Notes

FSPerson is the center of the object graph. Make all your changes to an FSPerson and then call save on that person.

Make a bunch of modifications to properties, relationships, etc and then call "save" on a person and it will commit all of it to the server.

Fetch does the same in reverse. It will fetch all properties and relationships from the server all at once.

Make sure you do not call save/fetch on the main thread.

See the header files for the full API and more documentation.

### Usage

Use FSAuth to log in and get a session id:

	FSAuth *auth = [[FSAuth alloc] initWithDeveloperKey:SANDBOXED_DEV_KEY];
	MTPocketResponse *response = [auth loginWithUsername:SANDBOXED_USERNAME password:SANDBOXED_PASSWORD];
	
	if (response.success) {
		_sessionID = auth.sessionID;;
	}

If you want to use the sandbox environment:

	[FSURL setSandboxed:YES];

Get information about yourself:

	FSPerson *me = [FSPerson currentUserWithSessionID:_sessionID];
	MTPocketResponse *response = [me fetch];
	if (response.success) {
		me.name 									// => @"Adam Kirk"
		me.isAlive									// => YES
		me.gender 									// => @"Male"
		me.parents.count							// => 2
		[me getProperty:FSPropertyTypeOccupation];	// => @"Saint"
	}

Get information about someone else:

	FSPerson *you = [FSPerson personWithSessionID:_sessionID identifier:@"BLAH-BLAH"];
	MTPocketResponse *response = [you fetch];
	if (response.success) {
		you.name 				// => @"Gamima Smitty"
		you.gender 				// => @"Female"
		you.parents.count		// => 1
	}

Create a person:

	person = [FSPerson personWithSessionID:_sessionID identifier:nil];
	person.name = @"Adam Kirk";
	person.gender = @"Male";
	MTPocketResponse *response = [person save];

Update a person:

	person = [FSPerson personWithSessionID:_sessionID identifier:@"BLAH-BLAH"];
	[person setProperty:@"Programmer" forKey:FSPropertyTypeOccupation];
	[person save];

Add/Remove a parent:

	person.parents.count	// => 0
	
	FSPerson *father = [FSPerson personWithSessionID:_sessionID identifier:nil];
	father.name = @"Nathan Kirk";
	father.gender = @"Male";
	
	[person addParent:father withLineage:FSLineageTypeBiological];
	[person save];
	
	person.parents.count	// => 1
	
	[person removeParent:father];
	[person save];
	
	person.parents.count	// => 0

Add/Remove a child:

	person.children.count	// => 0
	
	FSPerson *child = [FSPerson personWithSessionID:_sessionID identifier:nil];
	child.name = @"Jim Kirk";
	child.gender = @"Male";
	
	[person addChild:child withLineage:FSLineageTypeAdoptive];
	[person save];
	
	person.children.count	// => 1
	
	[person removeChild:child];
	[person save];
	
	person.children.count	// => 0

Add/Remove a spouse:

	person.spouses.count 	// => 0
	
	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
	spouse.name = @"She Kirk";
	spouse.gender = @"Female";
	
	[person addSpouse:spouse];
	[person save];
	
	person.spouses.count	// => 1
	
	[person removeSpouse:spouse];
	[person save];
	
	person.spouses.count	// => 0

Add/Remove an Event:

	person.events.count		// => 0
	
	FSEvent *death = [FSEvent eventWithType:FSPersonEventTypeDeath identifier:nil];
	death.date = [NSDate dateFromYear:1995 month:8 day:11 hour:10 minute:0];
	death.place = @"Kennewick, WA";
	[person addEvent:death];
	
	FSEvent *event = [FSEvent eventWithType:FSPersonEventTypeBaptism identifier:nil];
	event.date = [NSDate dateFromYear:1994 month:8 day:11 hour:10 minute:0];
	event.place = @"Kennewick, WA";
	[person addEvent:event];
	[person save];
	
	person.events.count		// => 2
	
	[person removeEvent:event];
	[person save];
	
	person.events.count		// => 1	

Convenience Events:
	
	person.birthDate	= [NSDate dateFromYear:1995 month:8 day:11 hour:0 minute:0];
	person.birthPlace	= @"Kennewick, Benton, Washington, United States";
	person.deathDate	= [NSDate dateFromYear:1994 month:8 day:11 hour:0 minute:0];
	person.deathPlace	= @"Pasco, Franklin, Washington, United States";
	[person save];

Add/Read Marriage Properties:

	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
	spouse.name = @"She Man";
	spouse.gender = @"Female";
	FSMarriage *marriage = [person addSpouse:spouse];
	[person save];
	
	person.spouses.count	// => 1
	
	[marriage setProperty:@"2" forKey:FSMarriagePropertyTypeNumberOfChildren];
	[marriage setProperty:@"True" forKey:FSMarriagePropertyTypeCommonLawMarriage];
	[person save];
	
	FSPerson *p = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
	[p fetch];
	FSMarriage *m = [p marriageWithSpouse:spouse];
	[m propertyForKey:FSMarriagePropertyTypeNumberOfChildren]	// => @"2"
	[m propertyForKey:FSMarriagePropertyTypeCommonLawMarriage]	// => @"True"

Add/Remove a Marriage Event:

	person.spouses.count	// => 0
	
	FSPerson *spouse = [FSPerson personWithSessionID:_sessionID identifier:nil];
	spouse.name = @"She Man";
	spouse.gender = @"Female";
	FSMarriage *marriage = [person addSpouse:spouse];
	[person save];
	
	person.spouses.count	// => 1
	
	marriage.events.count	// => 0
	
	FSMarriageEvent *event = [FSMarriageEvent marriageEventWithType:FSMarriageEventTypeMarriage identifier:nil];
	event.date = [NSDate dateFromYear:1994 month:8 day:11 hour:10 minute:0];
	event.place = @"Kennewick, WA";
	[marriage addMarriageEvent:event];
	[person save];
	
	marriage.events.count	// => 1
	
	[marriage removeMarriageEvent:event];
	[person save];
	
	person = [FSPerson personWithSessionID:_sessionID identifier:person.identifier];
	[person fetch];
	FSMarriage *m = [person marriageWithSpouse:spouse];
	
	m.events.count			// => 0

### Properties

	FSPropertyTypeCasteName			
	FSPropertyTypeClanName			
	FSPropertyTypeNationalID		
	FSPropertyTypeNationalOrigin	
	FSPropertyTypeTitleOfNobility	
	FSPropertyTypeOccupation		
	FSPropertyTypePhysicalDescription
	FSPropertyTypeRace				
	FSPropertyTypeReligiousAffiliation
	FSPropertyTypeStillborn			
	FSPropertyTypeTribeName			
	FSPropertyTypeGEDCOMID			
	FSPropertyTypeCommonLawMarriage	
	FSPropertyTypeOther				
	FSPropertyTypeNumberOfChildren	
	FSPropertyTypeNumberOfMarriages	
	FSPropertyTypeCurrentlySpouses	
	FSPropertyTypeDiedBeforeEight	
	FSPropertyTypeNameSake			
	FSPropertyTypeNeverHadChildren	
	FSPropertyTypeNeverMarried		
	FSPropertyTypeNotAccountable	
	FSPropertyTypePossessions		
	FSPropertyTypeResidence			
	FSPropertyTypeScholasticAchievement
	FSPropertyTypeSocialSecurityNumber
	FSPropertyTypeTwin

### Marriage Properties

	FSMarriagePropertyTypeGEDCOMID		
	FSMarriagePropertyTypeCommonLawMarriage
	FSMarriagePropertyTypeNumberOfChildren
	FSMarriagePropertyTypeCurrentlySpouses
	FSMarriagePropertyTypeNeverHadChildren
	FSMarriagePropertyTypeNeverMarried	
	FSMarriagePropertyTypeOther

### Lineage Types

	FSLineageTypeBiological		
	FSLineageTypeAdoptive		
	FSLineageTypeFoster			
	FSLineageTypeGuardianship	
	FSLineageTypeStep			
	FSLineageTypeUnknown		
	FSLineageTypeHeadOfHousehold
	FSLineageTypeOther

### Event Types

	FSPersonEventTypeAdoption		
	FSPersonEventTypeAdultChristening
	FSPersonEventTypeBaptism		
	FSPersonEventTypeConfirmation	
	FSPersonEventTypeBirth			
	FSPersonEventTypeBlessing		
	FSPersonEventTypeBurial			
	FSPersonEventTypeChristening	
	FSPersonEventTypeCremation		
	FSPersonEventTypeDeath			
	FSPersonEventTypeGraduation		
	FSPersonEventTypeImmigration	
	FSPersonEventTypeMilitaryService
	FSPersonEventTypeMission		
	FSPersonEventTypeMove			
	FSPersonEventTypeNaturalization	
	FSPersonEventTypeProbate		
	FSPersonEventTypeRetirement		
	FSPersonEventTypeWill			
	FSPersonEventTypeCensus			
	FSPersonEventTypeCircumcision	
	FSPersonEventTypeEmigration		
	FSPersonEventTypeExcommunication
	FSPersonEventTypeFirstCommunion	
	FSPersonEventTypeFirstKnownChild
	FSPersonEventTypeFuneral		
	FSPersonEventTypeHospitalization
	FSPersonEventTypeIllness		
	FSPersonEventTypeNaming			
	FSPersonEventTypeMiscarriage	
	FSPersonEventTypeOrdination		
	FSPersonEventTypeOther

### Marriage Event Types

	FSMarriageEventTypeAnnulment		
	FSMarriageEventTypeDivorce			
	FSMarriageEventTypeDivorceFiling	
	FSMarriageEventTypeEngagement		
	FSMarriageEventTypeMarriage			
	FSMarriageEventTypeMarriageBanns	
	FSMarriageEventTypeMarriageContract	
	FSMarriageEventTypeMarriageLicense	
	FSMarriageEventTypeCensus			
	FSMarriageEventTypeMission			
	FSMarriageEventTypeMarriageSettlement
	FSMarriageEventTypeSeperation		
	FSMarriageEventTypeTimeOnlyMarriage	
	FSMarriageEventTypeOther

### Testing

To run the unit tests, you need to create the missing "constant.h" file with the following contents:

	#define SANDBOXED_DEV_KEY	@"<sandboxed dev key>"
	#define SANDBOXED_USERNAME	@"<sandboxed username>"
	#define SANDBOXED_PASSWORD	@"<sandboxed password>"

	#define PRODUCTION_DEV_KEY	@"<live dev key>"
	#define PRODUCTION_USERNAME	@"<live username>"
	#define PRODUCTION_PASSWORD	@"<live password>"