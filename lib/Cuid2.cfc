/**
* This is a ColdFusion port of cuid2 by Eric Elliott.
* --
* Read more: https://github.com/paralleldrive/cuid2 
*/
component
	output = false
	hint = "I provide secure, collision-resistant ids optimized for horizontal scaling and performance."
	{

	this.SHA3_256 = "sha3-256";
	this.SHA_256 = "sha-256";

	/**
	* I initialize the CUID2 generator with the given (optional) parameters.
	*/
	public void function init(
		numeric length,
		string fingerprint,
		string algorithm
		) {

		variables.minCuidLength = 24;
		variables.maxCuidLength = 32;

		// The set of letters that can be used to start the CUID token.
		variables.letters = [
			"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
			"n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
		];

		// The counter will increment "forever" and is used as part of the hash inputs.
		// The assumption here is that the service will be restarted / redeployed before
		// the counter's Long value runs "out of space". The counter will start at a
		// random value for additional entropy.
		variables.counter = createObject( "java", "java.util.concurrent.atomic.AtomicLong" )
			.init( secureRandRange( 0, 2057 ) )
		;

		variables.secureRandom = createObject( "java", "java.security.SecureRandom" )
			.init()
		;

		// Shared class definitions as a performance optimization.
		variables.BigIntegerClass = createObject( "java", "java.math.BigInteger" );
		variables.MessageDigestClass = createObject( "java", "java.security.MessageDigest" );

		// Store and test arguments.
		variables.cuidLength = testCuidLength( arguments.length ?: minCuidLength );
		variables.processFingerprint = testProcessFingerprint( arguments.fingerprint ?: generateFingerprint() );
		variables.hashAlgorithm = testHashAlgorithm( arguments.algorithm ?: this.SHA3_256 );

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

		// The full generated token will always be longer than the desired CUID token due
		// to the underlying hashing algorithm (64-byte output). As such, let's ensure the
		// exact length by taking only the necessary prefix.
		return( token.left( cuidLength ) );

	}

	// ---
	// PRIVATE METHODS.
	// ---

	/**
	* I generate a secure random binary value of the given length.
	*/
	private array function generateBytes( required numeric length ) {

		var bytes = [];
		arrayResize( bytes, length );
		arraySet( bytes, 1, length, 0 );

		var javaBytes = javaCast( "byte[]", bytes );
		secureRandom.nextBytes( javaBytes );

		return( javaBytes );

	}


	/**
	* I generate the device fingerprint for the CUID.
	* 
	* DIVERGENCE FROM CUID v1: In first version of CUID, the fingerprint generation was
	* guaranteed to be 4-characters. However, in CUID v2, the fingerprint is nothing more
	* than a source of additional entropy for use in the hash-generation. As such, this
	* function no longer needs to make any guarantees about its length. In fact, doesn't
	* even need to use the process name.
	*/
	private string function generateFingerprint() {

		var jvmProcessName = createObject( "java", "java.lang.management.ManagementFactory" )
			.getRuntimeMXBean()
				.getName()
		;

		return( jvmProcessName );

	}


	/**
	* I generate the secure hash block for the CUID.
	*/
	private string function generateHashBlock() {

		var inputs = MessageDigestClass.getInstance( hashAlgorithm );

		// These are all just sources of entropy to aide in collision prevention. None of
		// the individual parts holds any particular magical meaning.
		inputs.update( generateBytes( maxCuidLength * 2 ) );
		inputs.update( charsetDecode( getTickCount(), "utf-8" ) );
		inputs.update( charsetDecode( counter.getAndIncrement(), "utf-8" ) );
		inputs.update( charsetDecode( processFingerprint, "utf-8" ) );

		var result = BigIntegerClass
			.init( inputs.digest() )
			.toString( 36 )
		;

		// NOTE: In the JavaScript version of CUID2, Eric Elliott removes the first two
		// letters of the hash. His note says that the first two letters bias the
		// generated CUIDs towards a narrower set of values. Anecdotally, I do see the
		// dash ("-") showing up a lot unless I remove the first 2 characters as well.
		return( result.right( result.len() - 2 ) );

	}


	/**
	* I generate the single letter to be used as the CUID token prefix.
	*/
	private string function generateLetterBlock() {

		return( letters[ secureRandRange( 1, letters.len() ) ] );

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
	* I test and return the given hash algorithm, throwing an error if the algorithm is
	* not supported.
	*/
	private string function testHashAlgorithm( required string value ) {

		value = value.lcase();

		if (
			( value != this.SHA3_256 ) &&
			( value != this.SHA_256 )
			) {

			throw(
				type = "Cuid2.Algorithm.NotSupported",
				message = "Cuid2 hashing algorithm not supported.",
				detail = "At this time, only the following hashing algorithms are supported: [#this.SHA3_256#, #this.SHA_256#]."
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

		return( value );

	}

}
