component
	output = false
	hint = "I define the application settings and event handlers."
	{

	// Define the application settings.
	this.name = "CUIDv2Testing";
	this.applicationTimeout = createTimeSpan( 1, 0, 0, 0 );
	this.sessionManagement = false;
	this.setClientCookies = false;

	this.directory = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings = {
		"/lib": "#this.directory#../lib"
	};

}
