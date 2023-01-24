component
	output = false
	hint = "I instrument a given ColdFusion component."
	{

	/**
	* I instrument each method within the given target ColdFusion component and return a
	* struct that will contain the aggregate execution times for each method, by name.
	*/
	public struct function instrument( required any target ) {

		var timings = {};

		// Slide the injector method right into the public scope and invoke it.
		target.__inspector__ = variables.inspector;
		target.__inspector__( timings );

		return( timings );

	}

	// ---
	// PRIVATE METHODS.
	// ---

	/**
	* I inspect the CURRENT CONTEXT, replacing each method with one that proxies the
	* original methods and records the execution times.
	*/
	private void function inspector( required struct targetMethodTimings ) {

		// CAUTION: This method is being invoked IN THE CONTEXT OF THE TARGET COMPONENT.
		// As such, both the THIS and VARIABLES references here are scoped to the target
		// component, not to the Instrumenter component!
		getMetadata( this ).functions.each(
			( method ) => {

				var scope = ( method.access == "public" )
					? this
					: variables
				;

				var originalName = method.name;
				var proxyName = ( "__" & method.name & "__" );

				// Setup the default timings entry for this method.
				targetMethodTimings[ originalName ] = 0;

				// COPY the original function reference into the private scope where it
				// can be invoked from our proxy function without muddying-up the public
				// API of the original component.
				variables[ proxyName ] = scope[ originalName ];
				// OVERRIDE the original function with our properly-scoped proxy.
				scope[ originalName ] = () => {

					var startedAt = getTickCount();

					try {

						return( invoke( variables, proxyName, arguments ) );

					} finally {

						targetMethodTimings[ originalName ] += ( getTickCount() - startedAt );

					}

				};

			}
		);

	}

}
