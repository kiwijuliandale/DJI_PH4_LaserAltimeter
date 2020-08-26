

# DJI Phantom 3/4 laser altimeter installation

Before we begin, there are some important warnings…

**WARNING** 
Modifying the DJI will void any warranties and could damage the aircraft. Only perform these modifications if you have adequate technical skills to 
perform the modifications.

**Disclaimer** 
The information provided by [Julian Dale or Duke University MaRRS Lab] (“we,” “us” or “our”) on [marineuas.net or Github/marrs-lab] (the “Site”) is for general informational purposes only. All information on the Site is provided in good faith, however we make no representation or warranty of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability or completeness of any information on the Site.

Under no circumstance shall we have any liability to you for any loss or damage of any kind incurred as a result of the use of the site or reliance on any information provided on the site. Your use of the site and your reliance on any information on the site is solely at your own risk. 


About the information included:

>I have included a tutorial video on how to install the power feed from the DJI battery. (By no means my best work but should provide the necessary information!!)
This allows the laser to power from the aircraft and will automatically start when the aircraft powers up. This saves weight and the risk of a separate power supply going flat. If you feel at all uncomfortable disassembling your aircraft, then use an external USB power bank or small LiPo battery. Please find the video tutorial here https://vimeo.com/451298704 

There are three folders containing ;

| Folder | Description |
| ------ | ------ |
| 3D Printer Files | STL's for printing the mouting frame |
| Arduino Code | Arduino code and libraries for the sensors. I have included the instructions from Steve Dawson & Hamish Bowman’s (Departments of Marine Science and Geology, University of Otago, Dunedin New Zealand) This is all their work and code and I have just included this as a reference |
| Assembly | Some assembly images and references. We have been using modified SF11C laser settings with good results over the water. Information on these settings are included in the assembly folder |


**Making Photogrammetry measurements:**
Because the laser altimeter is measuring a hypotenuse length, you need to calculate the vertical distance with a basic trig function. This can be done in excel.
Once this is done, KC Bierlich, Walter Torres and Clara Bird have developed some amazing tools for making the measurements in MorhhometriX and Collatrix for collating the data outputs. 
https://github.com/wingtorres/morphometrix
https://github.com/cbirdferrer/collatrix






