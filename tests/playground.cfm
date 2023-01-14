<cfscript>

	// Cachced reference to the CUID library.
	cuid2 = new lib.Cuid2();

	writeDump({ token: cuid2.createCuid() });
	writeDump({ token: cuid2.createCuid() });
	writeDump({ token: cuid2.createCuid() });
	writeDump({ token: cuid2.createCuid() });

</cfscript>
