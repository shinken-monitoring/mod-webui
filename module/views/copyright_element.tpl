%if not 'app' in locals(): app = None
%from shinken.bin import VERSION

<!-- 
	This file is part of Shinken.

 	Shinken is free software: you can redistribute it and/or modify it under the terms of the
 	GNU Affero General Public License as published by the Free Software Foundation, either
 	version 3 of the License, or (at your option) any later version.

	WebUI Version: {{app.webui_version}}
	Shinken Framework Version: {{VERSION}}
-->

