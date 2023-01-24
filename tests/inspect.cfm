<cfscript>

	cfsetting( requestTimeout = 300 );

	length = 24;
	cuid = new lib.Cuid2( length );
	count = 100000;

	// Inject all the proxy timing methods into the CUID instance.
	timings = new Instrumenter().instrument( cuid );

	for ( i = 1 ; i <= count ; i++ ) {

		token = cuid.createCuid()

	}

	writeDump(
		label = "CUID Execution Times (#numberFormat( count )# Tokens)",
		var = timings
	);

	writeDump({
		"last-token": token
	})

</cfscript>
