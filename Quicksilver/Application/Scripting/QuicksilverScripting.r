#include <Carbon/Carbon.r>

#define Reserved8   reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved
#define Reserved12  Reserved8, reserved, reserved, reserved, reserved
#define Reserved13  Reserved12, reserved
#define dp_none__   noParams, "", directParamOptional, singleItem, notEnumerated, Reserved13
#define reply_none__   noReply, "", replyOptional, singleItem, notEnumerated, Reserved13
#define synonym_verb__ reply_none__, dp_none__, { }
#define plural__    "", {"", kAESpecialClassProperties, cType, "", reserved, singleItem, notEnumerated, readOnly, Reserved8, noApostrophe, notFeminine, notMasculine, plural}, {}

resource 'aete' (0, "Quicksilver") {
	0x1,  // major version
	0x0,  // minor version
	english,
	roman,
	{
		"Standard Suite",
		"Common classes and commands for most applications.",
		'????',
		1,
		1,
		{
			/* Events */

			"open",
			"Open an object.",
			'aevt', 'odoc',
			reply_none__,
			'file',
			"The file(s) to be opened.",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			},

			"print",
			"Print an object.",
			'aevt', 'pdoc',
			reply_none__,
			'file',
			"The file(s) or document(s) to be printed.",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			},

			"quit",
			"Quit an application.",
			'aevt', 'quit',
			reply_none__,
			dp_none__,
			{
				"saving", 'savo', 'savo',
				"Specifies whether changes should be saved before quitting.",
				optional,
				singleItem, enumerated, Reserved13
			},

			"close",
			"Close an object.",
			'core', 'clos',
			reply_none__,
			'obj ',
			"the object to close",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"saving", 'savo', 'savo',
				"Specifies whether changes should be saved before closing.",
				optional,
				singleItem, enumerated, Reserved13,
				"saving in", 'kfil', 'file',
				"The file in which to save the object.",
				optional,
				singleItem, notEnumerated, Reserved13
			},

			"count",
			"Return the number of elements of a particular class within an object.",
			'core', 'cnte',
			'long',
			"the number of elements",
			replyRequired, singleItem, notEnumerated, Reserved13,
			'obj ',
			"the object whose elements are to be counted",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"each", 'kocl', 'type',
				"The class of objects to be counted.",
				optional,
				singleItem, notEnumerated, Reserved13
			},

			"delete",
			"Delete an object.",
			'core', 'delo',
			reply_none__,
			'obj ',
			"the object to delete",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			},

			"duplicate",
			"Copy object(s) and put the copies at a new location.",
			'core', 'clon',
			reply_none__,
			'obj ',
			"the object(s) to duplicate",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"to", 'insh', 'insl',
				"The location for the new object(s).",
				required,
				singleItem, notEnumerated, Reserved13,
				"with properties", 'prdt', 'reco',
				"Properties to be set in the new duplicated object(s).",
				optional,
				singleItem, notEnumerated, Reserved13
			},

			"exists",
			"Verify if an object exists.",
			'core', 'doex',
			'bool',
			"true if it exists, false if not",
			replyRequired, singleItem, notEnumerated, Reserved13,
			'obj ',
			"the object in question",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			},

			"get",
			"Get the data for an object.",
			'core', 'getd',
			'****',
			"",
			replyRequired, singleItem, notEnumerated, Reserved13,
			'obj ',
			"",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			},

			"make",
			"Make a new object.",
			'core', 'crel',
			'obj ',
			"to the new object",
			replyRequired, singleItem, notEnumerated, Reserved13,
			dp_none__,
			{
				"new", 'kocl', 'type',
				"The class of the new object.",
				required,
				singleItem, notEnumerated, Reserved13,
				"at", 'insh', 'insl',
				"The location at which to insert the object.",
				optional,
				singleItem, notEnumerated, Reserved13,
				"with data", 'data', '****',
				"The initial data for the object.",
				optional,
				singleItem, notEnumerated, Reserved13,
				"with properties", 'prdt', 'reco',
				"The initial values for properties of the object.",
				optional,
				singleItem, notEnumerated, Reserved13
			},

			"move",
			"Move object(s) to a new location.",
			'core', 'move',
			reply_none__,
			'obj ',
			"the object(s) to move",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"to", 'insh', 'insl',
				"The new location for the object(s).",
				required,
				singleItem, notEnumerated, Reserved13
			},

			"save",
			"Save an object.",
			'core', 'save',
			reply_none__,
			'obj ',
			"the object to save, usually a document or window",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"in", 'kfil', 'file',
				"The file in which to save the object.",
				optional,
				singleItem, notEnumerated, Reserved13,
				"as", 'fltp', 'TEXT',
				"The file type in which to save the data.",
				optional,
				singleItem, notEnumerated, Reserved13
			},

			"set",
			"Set an object's data.",
			'core', 'setd',
			reply_none__,
			'obj ',
			"",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"to", 'data', '****',
				"The new value.",
				required,
				singleItem, notEnumerated, Reserved13
			}
		},
		{
			/* Classes */

			"item", 'cobj',
			"A scriptable object.",
			{
				"class", 'pcls', 'type',
				"The class of the object.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"properties", 'pALL', 'reco',
				"All of the object's properties.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12
			},
			{
			},
			"items", 'cobj', plural__,

			"application", 'capp',
			"An application's top level scripting object.",
			{
				"name", 'pnam', 'TEXT',
				"The name of the application.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"frontmost", 'pisf', 'bool',
				"Is this the frontmost (active) application?",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"version", 'vers', 'TEXT',
				"The version of the application.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12
			},
			{
				'docu', { },
				'cwin', { }
			},
			"applications", 'capp', plural__,

			"color", 'colr',
			"A color.",
			{
			},
			{
			},
			"colors", 'colr', plural__,

			"document", 'docu',
			"A document.",
			{
				"path", 'ppth', 'TEXT',
				"The document's path.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12,

				"modified", 'imod', 'bool',
				"Has the document been modified since the last save?",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"name", 'pnam', 'TEXT',
				"The document's name.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12
			},
			{
			},
			"documents", 'docu', plural__,

			"window", 'cwin',
			"A window.",
			{
				"name", 'pnam', 'TEXT',
				"The full title of the window.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12,

				"id", 'ID  ', 'nmbr',
				"The unique identifier of the window.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"bounds", 'pbnd', 'qdrt',
				"The bounding rectangle of the window.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12,

				"document", 'docu', 'docu',
				"The document whose contents are being displayed in the window.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"closeable", 'hclb', 'bool',
				"Whether the window has a close box.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"titled", 'ptit', 'bool',
				"Whether the window has a title bar.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"index", 'pidx', 'nmbr',
				"The index of the window in the back-to-front window ordering.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12,

				"floating", 'isfl', 'bool',
				"Whether the window floats.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"miniaturizable", 'ismn', 'bool',
				"Whether the window can be miniaturized.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"miniaturized", 'pmnd', 'bool',
				"Whether the window is currently miniaturized.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12,

				"modal", 'pmod', 'bool',
				"Whether the window is the application's current modal window.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"resizable", 'prsz', 'bool',
				"Whether the window can be resized.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"visible", 'pvis', 'bool',
				"Whether the window is currently visible.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12,

				"zoomable", 'iszm', 'bool',
				"Whether the window can be zoomed.",
				reserved, singleItem, notEnumerated, readOnly, Reserved12,

				"zoomed", 'pzum', 'bool',
				"Whether the window is currently zoomed.",
				reserved, singleItem, notEnumerated, readWrite, Reserved12
			},
			{
			},
			"windows", 'cwin', plural__
		},
		{
			/* Comparisons */
		},
		{
			/* Enumerations */
			'savo',
			{
				"yes", 'yes ', "Save the file.",
				"no", 'no  ', "Do not save the file.",
				"ask", 'ask ', "Ask the user whether or not to save the file."
			}
		},

		"Quicksilver",
		"commands and classes for Quicksilver scripting.",
		'DAED',
		1,
		1,
		{
			/* Events */

			"open URL",
			"Opens or selects a URL",
			'GURL', 'GURL',
			reply_none__,
			'TEXT',
			"the URL to open",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			},

			"show notification",
			"Display a notification",
			'DAED', 'ntfy',
			reply_none__,
			'TEXT',
			"title of notification",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{
				"text", 'nTxt', 'TEXT',
				"text of notification",
				required,
				singleItem, notEnumerated, Reserved13,
				"image name", 'imgN', 'TEXT',
				"image name for notification",
				required,
				singleItem, notEnumerated, Reserved13,
				"image data", 'imgP', 'PICT',
				"image data for notification",
				required,
				singleItem, notEnumerated, Reserved13
			},

			"show large type",
			"display text in large type",
			'DAED', 'larg',
			reply_none__,
			'TEXT',
			"text to display",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			}
		},
		{
			/* Classes */

			"application", 'capp',
			"",
			{
			},
			{
			},
			"applications", 'capp', plural__,

			"picture", 'PICT',
			"",
			{
			},
			{
			}
		},
		{
			/* Comparisons */
		},
		{
			/* Enumerations */
		},

		"Script Handlers",
		"handlers for actions and other scripts.",
		'DAEH',
		1,
		1,
		{
			/* Events */

			"process text",
			"process some text. Scripts with this handler gain a 'Process Text' action",
			'DAED', 'opnt',
			'****',
			"value to return to Quicksilver",
			replyRequired, singleItem, notEnumerated, Reserved13,
			'TEXT',
			"text to process",
			directParamRequired,
			singleItem, notEnumerated, Reserved13,
			{

			}
		},
		{
			/* Classes */

		},
		{
			/* Comparisons */
		},
		{
			/* Enumerations */
		}
	}
};
