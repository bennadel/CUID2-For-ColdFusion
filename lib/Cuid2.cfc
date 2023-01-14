/**
* This is a ColdFusion port of cuid2 by Eric Elliot.
* --
* Read more: https://github.com/paralleldrive/cuid2 
*/
component
	output = false
	hint = "I provide secure, collision-resistant ids optimized for horizontal scaling and performance."
	{

	/**
	* I initialize the CUID2 generator with the given (optional) parameters.
	*/
	public void function init(
		numeric length,
		string fingerprint
		) {

		variables.minCuidLength = 24;
		variables.maxCuidLength = 32;

		// The set of letters that can be used to start the CUID token.
		variables.letters = [
			"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
			"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
		];

		// The set of prime numbers that can be used to help generate entropy.
		variables.primeNumbers = [
			109717, 109721, 109741, 109751, 109789, 109793, 109807, 109819, 109829,
			109831
		];

		// The counter will increment "forever" and is used as part of the hash inputs.
		// The assumption here is that the service will be restarted / redeployed before
		// the counter's Long value runs "out of space". The counter will start at a
		// random value for additional entropy.
		variables.counter = createObject( "java", "java.util.concurrent.atomic.AtomicLong" )
			.init( secureRandRange( 0, 2057 ) )
		;

		// Shared class definitions as a performance optimization.
		variables.LongClass = createObject( "java", "java.lang.Long" );
		variables.BigIntegerClass = createObject( "java", "java.math.BigInteger" );

		// Store and test arguments.
		// --
		// CAUTION: These assignments must come last because generating the fingerprint
		// depends on other variables being defined.
		variables.cuidLength = testCuidLength( arguments.length ?: minCuidLength );
		variables.processFingerprint = testProcessFingerprint( arguments.fingerprint ?: generateFingerprint() );

	}

	// ---
	// PUBLIC METHODS.
	// ---

	/**
	* I generate a unique ID of the configured length. Guaranteed to start with a letter
	* and be of the configured length.
	*/
	public string function createCuid() {

		var token = ( generateLetterBlock() & generateHashBlock() );

		// The full generated token will always be longer than the desired CUID token. As
		// such, let's ensure the exact length by taking only the necessary prefix.
		return( token.left( cuidLength ) );

	}

	// ---
	// PRIVATE METHODS.
	// ---

	/**
	* I generate a random base32 string of the given length.
	*/
	private string function generateEntropy( required numeric length ) {

		var value = "";

		while ( value.len() < length ) {

			// NOTE: I don't understand the significance of using a prime number in this
			// random selection. This is what Eric Elliott is doing in his version. I've
			// left a comment asking about this:
			// --
			// https://github.com/paralleldrive/cuid2/issues/24#issuecomment-1381812737
			value &= toBase36( secureRandRange( 0, secureRandArrayValue( primeNumbers ) ) );

		}

		return( value.left( length ) );

	}


	/**
	* I generate the devince fingerprint for the CUID.
	* 
	* DIVERGENCE FROM CUID v1: In first version of CUID, the fingerprint generation was
	* guaranteed to be 4-characters. However, in CUID v2, the fingerprint is nothing more
	* than a source of additional entropy for use in the hash-generation. As such, this
	* function no longer needs to make any guarantees about its length. In fact, doesn't
	* even need to use process name.
	*/
	private string function generateFingerprint() {

		var jvmProcessName = createObject( "java", "java.lang.management.ManagementFactory" )
			.getRuntimeMXBean()
				.getName()
		;

		return( secureHash( jvmProcessName ) );

	}


	/**
	* I generate the secure hash block for the CUID.
	*/
	private string function generateHashBlock() {

		var timePart = toBase36( getTickCount() );
		var entropyPart = generateEntropy( cuidLength );
		var counterPart = toBase36( counter.getAndIncrement() );
		// All of the entropy between the time, the counter, the fingerprint, and the
		// additional random values all, ultimately, get hashed-down to a consistently-
		// sized block.
		var input = "#timePart##entropyPart##counterPart##processFingerprint#";

		return( secureHash( input, cuidLength ) );

	}


	/**
	* I generate the single letter to be used as the CUID token prefix.
	*/
	private string function generateLetterBlock() {

		return( secureRandArrayValue( letters ) );

	}


	/**
	* I hash the given input down to a base36 string. The length of the resultant value is
	* not consistent.
	* 
	* CAUTION: In the native implementation, Eric Elliott uses SHA3-256. However, the SHA3
	* algorithms weren't added to Java until version 9 - see this post by Pete Freitag -
	* https://www.petefreitag.com/item/843.cfm - As such, I'm using SHA-256 with the hopes
	* that this will be sufficiently secure.
	*/
	private string function secureHash(
		required string input,
		numeric tokenLength = maxCuidLength
		) {

		// From the JavaScript version: The salt should be long enough to be globally
		// unique across the full length of the hash. For simplicity, we use the same
		// length as the intended id output, defaulting to the maximum recommended size.
		var salt = generateEntropy( tokenLength );
		var text = ( input & salt );

		// The native ColdFusion hash() function always returns the value as a hex-encoded
		// string. However, we need to get it into a base36-encoded string. As such, we
		// need to decode the hex back into its binary value and then use the BigInteger
		// class to re-encode as base36.
		var bytes = binaryDecode( hash( text, "sha-256" ), "hex" );
		// NOTE: While the hash() method always returns a value with a consistent length,
		// converting the hex-encoded value into a base36-encoding value results in a
		// variable-length string.
		var result = BigIntegerClass
			.init( bytes )
			.toString( 36 )
			// NOTE: In the JavaScript version of CUID2, Eric Elliott removes the first
			// two letters of the hash. His note says that the first two letters bias the
			// generated CUIDs towards a narrower set of values. Anecdotally, I do see the
			// dash ("-") showing up a lot unless I remove the first 2 characters as well.
			.right( -2 )
		;

		return( result );

	}


	/**
	* I return a random value from the given array using the SHA1PRNG secure algorithm.
	*/
	private any function secureRandArrayValue( required array values ) {

		return( values[ secureRandRange( 1, values.len() ) ] );

	}


	/**
	* I get a random value within the given range, inclusive, using the SHA1PRNG secure
	* algorithm.
	*/
	private numeric function secureRandRange(
		required numeric minValue,
		required numeric maxValue
		) {

		return( randRange( minValue, maxValue, "sha1prng" ) );

	}


	/**
	* I test and return the given length, throwing an error if the length is invalid.
	*/
	private numeric function testCuidLength( required numeric value ) {

		if (
			( value < minCuidLength ) ||
			( value > maxCuidLength ) ||
			( fix( value ) != value )
			) {

			throw(
				type = "Cuid2.Length.Invalid",
				message = "Cuid2 token length must be between [#minCuidLength#] and [#maxCuidLength#].",
				detail = "Provided length: [#value#]."
			);

		}

		return( value );

	}


	/**
	* I test and return the given fingerprint, throwing an error if the fingerprint is
	* invalid.
	*/
	private string function testProcessFingerprint( required string value ) {

		if ( ! value.len() ) {

			throw(
				type = "Cuid2.Fingerprint.Invalid",
				message = "Cuid2 process fingerprint must not be empty.",
				detail = "The fingerprint provides an important source of device-related entropy and cannot be empty."
			);

		}

		return( value )

	}


	/**
	* I convert the given number into a Base36 character encoding.
	*/
	private string function toBase36( required numeric input ) {

		// NOTE: Not all of the values we are dealing with can fit inside an INT. And,
		// Adobe ColdFusion can only use INTs with the formatBaseN() function (Note that
		// Lucee CFML does not have this constraint). As such, we're dipping into the Long
		// class for our encoding.
		return( LongClass.toString( input, 36 ) );

	}

}
