<cfscript>

	cfsetting( requestTimeout = 300 );

	length = 24;
	cuid = new lib.Cuid2( length );
	count = 1000000;
	tokens = [:];
	buckets = [:];
	BigIntegerClass = createObject( "java", "java.math.BigInteger" );

	// Create buckets for our distribution counters. As each CUID is generated, it will be
	// sorted into one of these buckets (used to increment the given counter).
	for ( i = 1 ; i <= 20 ; i++ ) {

		buckets[ i ] = 0;

	}

	bucketCount = BigIntegerClass.init( buckets.count() );
	startedAt = getTickCount();

	for ( i = 1 ; i <= count ; i++ ) {

		token = cuid.createCuid();

		// Make sure the CUID is generated at the configured length.
		if ( token.len() != length ) {

			throw(
				type = "Cuid2.Test.InvalidTokenLength",
				message = "Cuid token length did not match configuration.",
				detail = "Length: [#length#], Token: [#token#]"
			);

		}

		tokens[ token ] = i;

		// If the CUIDs are all unique, then each token should represent a unique entry
		// within the struct. But, if there is a collision, then a key will be written
		// twice and the size of the struct will no longer match the current iteration.
		if ( tokens.count() != i ) {

			throw(
				type = "Cuid2.Test.TokenCollision",
				message = "Cuid token collision detected in test.",
				detail = "Iteration: [#numberFormat( i )#]"
			);

		}

		// Each token is in the form of ("letter" + "base36 value"). As such, we can strip
		// off the leading letter and then use the remaining base36 value to generate a
		// BigInteger instance.
		intRepresentation = BigIntegerClass.init( token.right( -1 ), 36 );
		// And, from said BigInteger instance, we can use the modulo operator to sort it
		// into the relevant bucket / counter.
		bucketIndex = ( intRepresentation.remainder( bucketCount ) + 1 );
		buckets[ bucketIndex ]++;

	}

</cfscript>
<cfoutput>

	<p>
		Tokens generated: #numberFormat( count )# (no collisions)<br />
		Time: #numberFormat( getTickCount() - startedAt )#ms
	</p>

	<ol>
		<cfloop item="key" collection="#buckets#">
			<li>
				<div class="bar" style="width: #fix( buckets[ key ] / 100 )#px ;">
					#numberFormat( buckets[ key ] )#
				</div>
			</li>
		</cfloop>
	</ol>

	<style type="text/css">
		.bar {
			background-color: ##ff007f ;
			border-radius: 3px 3px 3px 3px ;
			color: ##ffffff ;
			margin: 2px 0px ;
			padding: 2px 5px ;
		}
	</style>

</cfoutput>
