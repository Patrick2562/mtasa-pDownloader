# pDownloader
Better looking progress bar and players can play while downloading files.

Video: https://streamable.com/bedf40

# How to use
If you want to enable pDownloader for a resource. (this resource called *vehiclemodels* in the examples)
1) Open *vehiclemodels/meta.xml*.
2) Add **<pDownloader>true</pDownloader>** tag to enable it.
3) **(!)** Disable downloading for every file, which you want to download with pDownloader, instead of the default one.

**Example: vehiclemodels/meta.xml**
```xml
<meta>
    <pDownloader>true</pDownloader> <!-- STEP 2 - enable pDownloader -->
    
    <script src="client.lua" type="client" />
    
    <!-- STEP 3 - disable downloading with  download="false"  attribute -->
    <file src="files/infernus.txd" download="false" />
    <file src="files/infernus.dff" download="false" />
</meta>
```

### (IMPORTANT) You can load models just after when every file was downloaded. (when pOnDownloadComplete called)

Example: *vehiclemodels/client.lua*

**(NOTE)** use resouceRoot for event's source
```lua
addEvent("pOnDownloadComplete", true)
addEventHandler("pOnDownloadComplete", resourceRoot, function()
    local txd = engineLoadTXD("files/infernus.txd")
    engineImportTXD(txd, 411)
    local dff = engineLoadDFF("files/infernus.dff")
    engineReplaceModel(dff, 411)
end)
```

### Thats all, now if somebody connect to your server, selected files are downloaded by pDownloader.

# 

# How to use model-loader
You can load your models with pDownloader, so you don't have to worry about it.

Just set the model ID in meta.xml, and loads automatically after download.

Example: *vehiclemodels/meta.xml*
```xml
<meta>
    <pDownloader>true</pDownloader> <!-- STEP 2 - enable pDownloader -->
  
    <!-- script file isn't needed -->
  
    <!-- STEP 3 - disable downloading with  download="false"  attribute -->
    <!-- and set model ID for the model-loader with  model="ID"  attribute-->
    <file src="files/infernus.txd" download="false" model="411" />
    <file src="files/infernus.dff" download="false" model="411" />
</meta>
```
**(NOTE)** If you want to load the same file to multiple models, just enter the IDs separated by commas.

Example:
```xml
<!-- load the same TXD to severals models -->
<file src="files/cars.txd" download="false" model="411,479,585,511" />
```

# Events

### **pOnFileDownloaded** (client)
Called when: file downloaded successfully.

Event's source is: root element of the resource that downloaded file.

Parameters:
- path:  File's path.
- model: Model ID. (if specified, nil otherwise)

### **pOnDownloadComplete** (client)
Called when: every file downloaded successfully inside a resource.

Event's source is: root element of the resource that downloaded file.

### **pOnDownloadFailed** (server)
Called when: file download failed and player get kicked.

Event's source is: player who can't download the file.

Parameters:
- path: File's path.


# Download Priority
You can set the priority in meta.xml by replace true to a number.

Resources with higher priority are downloaded before others.

**(NOTE)** default priority is 1 (when value is just `true`)

```xml
<pDownloader>10<pDownloader>
```