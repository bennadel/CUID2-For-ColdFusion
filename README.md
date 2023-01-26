
# CUID2 for ColdFusion

by [Ben Nadel][ben-nadel]

This is a **ColdFusion / CFML port** of the [Cuid2][cuid2] token generator created by [Eric Elliott][eric-elliott]. Cuid2 is an evolution of the [Cuid][cuid] library (for which I also have a [ColdFusion port][ben-nadel-cuid]) that is intended to address some security issues.

Each Cuid token starts with a letter and is a consistent, configured length between 24 (default) and 34 characters.

The Cuid library for ColdFusion is **thread safe** and is intended to be instantiated once within an application and then cached for future usage. The Cuid library exposes one public method, `.createCuid()`, which will generate and return your Cuid token:

```cfml
<cfscript>

	// Cachced reference to the CUID library.
	cuid2 = new lib.Cuid2();

	writeDump({ token: cuid2.createCuid() });
	writeDump({ token: cuid2.createCuid() });
	writeDump({ token: cuid2.createCuid() });
	writeDump({ token: cuid2.createCuid() });

</cfscript>
```

Running the above ColdFusion code will produce the following output:

```txt
token: uem955pnse56id49y6bcmjz8
token: ek9lgqi0mfkh9wmxnb6rvzuc
token: lycfyvl0dlspi0us6smqkkr0
token: x0hhypk7l7k4hga8newn4gnw
```

The `Cuid2.cfc` ColdFusion component can be instantiated with three optional arguments:

`new Cuid2( [ length [, fingerprint [, algorithm ] ] ] )`

* `length` - Numeric: The length of the generated token. Defaults to 24 but can be anything between 24 and 32.

* `fingerprint` - String: The machine fingerprint. This is provided as an additional source of entropy. It defaults to the name of the JVM process as reported by the `ManagementFactory` Runtime MX Bean.

* `algorithm` - String: The hash algorithm to be used when reducing the sources of entropy. It defaults to `SHA3-256` (which is the CUID2 standard); but, can also be set to `SHA-256` for older versions of Java (8) that don't support `SHA3` yet.

## Random Distribution

Under the hood, the `Cuid2.cfc` ColdFusion component generates random values using the `randRange()` built-in function with the `sha1prng` algorithm. With over 1,000,000 keys, we can see that this randomness is well distributed into buckets:

<img
	src="https://github.com/bennadel/CUID2-For-ColdFusion/raw/master/public/histogram.png"
	width="100%"
/>


[ben-nadel]: "https://www.bennadel.com/"

[ben-nadel-cuid]: https://github.com/bennadel/CUID-For-ColdFusion

[cuid]: https://github.com/paralleldrive/cuid

[cuid2]: https://github.com/paralleldrive/cuid2

[eric-elliott]: https://medium.com/@_ericelliott
