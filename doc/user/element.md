# Element properties for WebUI


## Notes
------------------------------------

Shinken core does not allow to define the *notes* property more than once ... and the *note* is defined as a simple text.

WebUI allows to use a simple syntax to enrich the element notes : 

- a double colon (::) allows to define a **title** and a **description** inside the note : title::description
- a double comma (,,) allows to define an **icon** and a **title** inside the title : title;;icon

A list of notes may be declared in the *notes* property. Notes are separated with a | character.

A list of notes url may be declared in the *notes_url* property. Notes url are separated with a | character.

Service/host definition :
```
define service{
   ...
   # Element notes definition:
   
   # Define a simple classic note
   #notes                Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin et leo gravida, lobortis nunc nec, imperdiet odio. Vivamus quam velit, scelerisque nec egestas et, semper ut massa. Vestibulum id tincidunt lacus. Ut in arcu at ex egestas vestibulum eu non sapien. Nulla facilisi. Aliquam non blandit tellus, non luctus tortor. Mauris tortor libero, egestas quis rhoncus in, sollicitudin et tortor.
   
   # Define a classic note with a title
   #notes                KB1023::note with a title

   # Define a note with a title and an icon
   #notes                KB1023,,tag::<strong>Lorem ipsum dolor sit amet</strong>, consectetur adipiscing elit. Proin et leo gravida, lobortis nunc nec, imperdiet odio. Vivamus quam velit, scelerisque nec egestas et, semper ut massa. Vestibulum id tincidunt lacus. Ut in arcu at ex egestas vestibulum eu non sapien. Nulla facilisi. Aliquam non blandit tellus, non luctus tortor. Mauris tortor libero, egestas quis rhoncus in, sollicitudin et tortor.

   # Define two notes with a title and an icon
   #notes                KB1023,,tag::<strong>Lorem ipsum dolor sit amet</strong>, consectetur adipiscing elit. Proin et leo gravida, lobortis nunc nec, imperdiet odio. Vivamus quam velit, scelerisque nec egestas et, semper ut massa. Vestibulum id tincidunt lacus. Ut in arcu at ex egestas vestibulum eu non sapien. Nulla facilisi. Aliquam non blandit tellus, non luctus tortor. Mauris tortor libero, egestas quis rhoncus in, sollicitudin et tortor.|KB1024,,tag::<strong>Lorem ipsum dolor sit amet</strong>, consectetur adipiscing elit. Proin et leo gravida, lobortis nunc nec, imperdiet odio. Vivamus quam velit, scelerisque nec egestas et, semper ut massa. Vestibulum id tincidunt lacus. Ut in arcu at ex egestas vestibulum eu non sapien. Nulla facilisi. Aliquam non blandit tellus, non luctus tortor. Mauris tortor libero, egestas quis rhoncus in, sollicitudin et tortor.

   notes_url            http://www.my-KB.fr?host=$HOSTADDRESS$|http://www.my-KB.fr?host=$HOSTNAME$
   
   ...
}
```

The element notes are located in the overview panel of the element view. Each note is displayed as a button including the **title** and the **icon**. The note **description** is displayed in a popover when hovering the title. If an Url is defined, the **title** is a navigable link.

![image](element-notes.jpg)





## Actions
------------------------------------

Shinken core does not allow to define the *note* property more than once ... and the *note* is defined as a simple text.

WebUI allows to use a simple syntax to enrich the element notes : 

- a double colon (::) allows to define a **title** and a **url** inside the action url : title::url
- a double comma (,,) allows to define an **icon** and a **title** inside the title : title;;icon
- a double comma (,,) allows to define a **description** for the url : description::url

Service/host definition :
```
define service{
   ...
   # Element actions definition:
   
   # List of actions (same syntax as for notes)
   action_url           http://www.google.fr|url1::http://www.google.fr|My KB,,tag::http://www.my-KB.fr?host=$HOSTNAME$|Last URL,,tag::<strong>description</strong>With a more important description of the link ...,,http://www.my-KB.fr?host=$HOSTADDRESS$

   ...
}
```

The action urls are located in a dropdown list of the element view. Each url is displayed as a list element including the **title** and the **icon**. The **description** is displayed in a popover when hovering the list element. If an Url is defined, the **list element** is a navigable link.


![image](element-urls.jpg)





## Company logo
------------------------------------

A company logo is used in the Web UI. The default company logo is a Shinken logo.

![Default company logo](../../module/htdocs/images/default_company.png "Default company logo")

To use another logo, the file name must be set in the *webui.cfg* file (*company_logo*) and the file must be copied in the *photos_dir (default is */var/lib/shinken/share/photos/*).


## User picture
------------------------------------

If gravatar is configured in the *webui.cfg* file, the Web UI tries to find a Gravatar image to use for the logged in user. Gravatar searched image is based upon the user configured email.

If gravatar is not configured in the *webui.cfg* file, the Web UI tries to find an image in a *username.png* file located in the *photos_dir* configured in the WebUI.

If none found, a default image is used.

![Default user logo](../../module/htdocs/images/default_user.png "Default user logo")

