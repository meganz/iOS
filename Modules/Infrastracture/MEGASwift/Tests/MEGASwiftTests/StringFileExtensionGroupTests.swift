@testable import MEGASwift
import XCTest

final class StringFileExtensionGroupTests: XCTestCase {
    private static let emptyExtension = ""
    private static let imageExtensions = ["3fr", "arw", "bmp", "cr2", "crw", "ciff", "cur", "cs1", "dcr", "dng", "erf", "gif", "heic", "ico", "iiq", "j2c", "jp2", "jpf", "jpeg", "jpg", "k25", "kdc", "mef", "mos", "mrw", "nef", "nrw", "orf", "pbm", "pef", "pgm", "png", "pnm", "ppm", "psd", "raf", "raw", "rw2", "rwl", "sr2", "srf", "srw", "tga", "tif", "tiff", "webp", "x3f"]
    private static let videoExtensions = ["3g2", "3gp", "avi", "m4v", "mov", "mp4", "mqv", "qt"]
    private static let audioExtensions = ["aac", "ac3", "aif", "aiff", "au", "caf", "eac3", "ec3", "flac", "m4a", "mp3", "wav"]
    private static let textPathExtension = ["txt", "ans", "ascii", "log", "wpd", "json", "md"]
    private static let webCodePathExtension = ["action", "adp", "ashx", "asmx", "asp", "aspx", "atom", "axd", "bml", "cer", "cfm", "cgi", "css", "dhtml", "do", "dtd", "eml", "htm", "html", "ihtml", "jhtml", "jsonld", "jsp", "jspx", "las", "lasso", "lassoapp", "markdown", "met", "metalink", "mht", "mhtml", "rhtml", "rna", "rnx", "se", "shtml", "stm", "wss", "yaws", "zhtml", "xml", "js", "jar", "java", "class", "php", "php3", "php4", "php5", "phtml", "inc", "pl", "py", "sql", "accdb", "db", "dbf", "mdb", "pdb", "c", "cpp", "h", "cs", "sh", "vb", "swift"]
    private static let maloneyBologna = """
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*##**+--::----==#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*#####*=-::---===#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*######*=::--==+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@**######*-:-==++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+######*=::=+***%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+-*######*-:-=+**%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@#-=*#####*+---++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+=**#%@@@@@%+=++*##*#*+=+==++%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+::::-=++--===++==-=+=+**=+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=-:::::::+*=+*+=--===**+=+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=+=--:::::-====##=-----+**==++*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:==--:::::::--=*++=---=+++=++==+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:::::---:::---====*+======------=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+::::--::-:::::---=+=--::::::-====#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@**#+-:::::-:---------:--==-::::::----=++%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@%-:::::::-:-:-=--=--+=---=*+=--:::::-----+*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@+---::---:--+=---===++===+**+---::-::-===++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@+-:::-:::::-=+========+++=+*+=-==-::::-===-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@#:::---------:---==+++--====**+===+--:----==-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@#:::::--::---------=+****++++=++++==+-=----==--%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@#-::--=-------===++=-=+*##*****+++++=++=+===---+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@=------::--::---==+++=+**********+*++=++=+==---*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@#+==-----::::-==+++***++*********++++==*+++++---=@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@#==------::::---==+***********+++=+=+=+*=+++=--+@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@+-::----:--::---=+************+++++=++++==+++--*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@%=----::-------=++*****************++++++++++*=-#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@#-:=---==--===+**********##**********++++**+*+-%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@=-========++++**********####****##*****++**==-*@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@#--=-=====+++++***********###*#**####****++**+-=@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@%--==--===+*****************#***######*****++++=-%@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@#--=====+************************#######****+====%@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@+-=++*++**+++++*****************#########***++=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@*-=+*++++++++++++****************##########***+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@*-=+*+===++++++++++***************##########***@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@+=+*+=+==++++++++++++************#*#########**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@%++*+====++++++++++++****************#######**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@*+*+===++++++++++++++****************######**@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@#+*+==+++++++++++++++*****************#####*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@#**+==+++++++++++++++*****************#####*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@#+*+==+++++++++++++++*****************#####*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@**++==+++++++++++++******************#####*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@**+=--==+++***+++++*********#*********####*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@#*+--=+++++++****+********************####*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@#############****************######*#######*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@####******######*********##%%######%######*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@###***##*****#####*****#%%###*******######*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@*##*#########**###****#%#**##%%%%###*####*+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@#=*#*###########*###**#%#*#%%%%%%%%%#*###***+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@%-=*#*###########**#**##%*#%%%%%%%%%%#*###*#*++#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@*--+##*##########*##**##%##%%%%%%%%%%#*%###**+++#@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@+=-=*#*##########*##****###%%%%%%%%%%*#%#****+=*+#@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@#===+#**########**##****###%%%%%%%%%#*##*****++***@@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@+-===*#**#######*####**##%##%%%%%%%#*###*****+++*+#@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@%:---=+*#****##***###***####*#%%%%%#**%#**#***+==++*@@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@+-==--==+###****###*****##########**#%#******+=-==++#@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@#:=-=---===+*#####***++***####%#####%##*******=---==+*@@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@%==++==---===++***++++++++**#**#######********+==+===++%@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@#-++==----====++++++++++++++**++**************++++==+++%@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@+-==------=====++++++++++*****++++***********++++===+++%@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@#====-----=======++++++++++***++++++++********+==+++++++*@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@%+-:------=========++++++++++****++++++++++***#*+++*+==++++@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@#=--::-==---+======++++++++******++++++++++++*##++++*+=-=++@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@#------====+=======+++*++++*******##*++++++++*##*+****++==*@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@#+===-----=+*++======+*****########***++++++++###*++###*++++@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@+==::----=*#*+++=====+++++++++********+++++++*####++*****=-=@@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@%=::::-:-=***+++**====++++++===++++****++++++*#####*++++++=-:*@@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@%=--:-:--=+++==*+***====+==++++++++++***+++++*######*+*#***+=-:+@@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@#-:-=-::-======+++**#*+======+++++++++***++++*########*+**####*+-=@@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@#+-----:-=--===++++**##*+======+++++***++++++*#########*++*#**++=-:=@@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@+::::::::=-:-==+*#****#***++=====+++++++++++**##########*******+===::*@@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@----:---===+***##*+***#****+++====++++++++****##########**#*+++===+===%@@@@@@@@@@@@@@@@@
    @@@@@@@@@@@#-:::-::=+*********++******+++++===++++++******##########**##*++===+**+=@@@@@@@@@@@@@@@@@
    @@@@@@@@@@%-::-=-:=+********#*++******+*++++++++++*******#*#########******++****++=+@@@@@@@@@@@@@@@@
    @@@@@@@%=--:------=+++********+**********++++++*********#**########**##*****++*#*+++%@@@@@@@@@@@@@@@
    @@@@@@@@%=-:---:-=----==+++***++**********++***********##**########**###*+++**##**++*@@@@@@@@@@@@@@@
    @@@@@@%*=-:--=:--=+**+=++++++*++******#***++************##*#######*+*###*===**#%*+==+*@@@@@@@@@@@@@@
    @@@@@@%+==-=-:---=**++=====+*##+*******##************#***##***#**#*+*#####++###*+==+**#@@@@@@@@@@@@@
    @@@@@@#==---:---==++++==--=*#%#******#**#***********###**#*****###*+**###########****#*@@@@@@@@@@@@@
    @@@@@@*+=--:--=---===-==-=*####**#****++*##*****#########****#####++**######**##********@@@@@@@@@@@@
    @@@@@@++==:--=+-===***##*#%%%%%**##*++**+*########*#####*****#####++*###############****#@@@@@@@@@@@
    @@@@#==--::-=======#####%%%%%%%#**#*+++++++*###*****####*****#####++#%##*####*##**#******%@@@@@@@@@@
    @@@@@%#*=:=+==+==++#####%%%%%%%#**##*++++*+++++++****##***#**####*++#%%##***+*####*******+%@@@@@@@@@
    @@@@@@@%-======+++**####%%%%%%%%**###*++++++++++++*****###***####*++%%%%%%%%%%%%#******#***@@@@@@@@@
    @@@@@@@*-+++===++***####%%%%%%%%**###**+++++++++++++++*###***####+++%%%%%%%%%%%%#**#**##*#*#@@@@@@@@
    @@@@@@@==++===++++**###%%%%%%%%%*+####***+++++==++++++*##****##%#++*%%%%%%%%%%%%####**#*##**%@@@@@@@
    @@@@@@#-+*+=++*++=+*####%%%%%%%%#+*%##*****+++++++++**##******#%#++*%%%%%%%#%%%%#####********@@@@@@@
    @@@@@@=-**+++***+=+*###%%%%%%%%%%**%###*******++++****##******#%*=+#%%%%%%%%%%%%%####******#**@@@@@@
    @@@@@%=+*++++++*+=+*###%%%%%%%%%%**#%##**************##******###+=+%%%%%%%%%%%%%##*##*******#**@@@@@
    @@@@@+=+*++++==+++++###%%%%%%%%%%#+*%###*************#*******#%#+=+%%%%%%%%%%%%%###****#**#****#@@@@
    @@@@+++=++*++=====++##%%%%%%%%%%%%**#%##*********+**##******##%#==*%%%%%%%%%%%%%%##***###*##+***#@@@
    @@@#-+==+**+++=+==+*#%%%%%%%%%%%%%#+*%%##*****++++**##******##%*==#%%%%%%%%%%%%%###***#####**#***%@@
    @@%=+++=++*+==+*==+*#%%%%%%%%%%%%%#**#%##******+***##*******#%#+=+#%%%%%%%%%%%%%###########*##**+*@@
    @@=-**+=+++===+*+=+*%%%%%%%%%%%%%%%*+*%%##******##*##*******#%#+=*%%%%%%%%%%%%%%%#######*#**#****+*@
    @*-+++++=++===+*+=+*%%%%%%%%%%%%%%%#+*#%##******##*#********#%#==*%%%%%%%%%%%%%%%#########*###****=#
    %-====+==++++++++++#%%%%%%%%%%%%%%%%*+*%%###*******#********#%*==#%%%%%%%%%%%%%%%##*#############*+*
    -=========+++++++++#%%%%%%%%%%%%%%%%#*+#%####*****##********#%+=+%%%%%%%%%%%%%%%%%##**###########***
    =+===++====*+++++++#%%%%%%%%%%%%%%%%%*+*%%####*****#*******#%#==*%%%%%%%%%%%%%%%%%%#***##########*#*
    ==+==+*+==+***++++*%%%%%%%%%%%%%%%%%%#++#%#####************#%#==*%%%%%%%%%%%%%%%%%%##**##*##*####*#*
    ==+===+*==*#**++*+*%%%%%%%%%%%%%%%%%%%*+*%%#####****#*****%#%*==#%%%%%%%%%%%%%%%%%%###*##****####**#
    =+==++++++*#**==+**%%%%%%%%%%%%%%%%%%%#*+#%######***#*****%%%+=+%%%%%%%%%%%%%%%%%%%###*******####**#
    ++===++=+++#*+==+*#%%%%%%%%%%%%%%%%%%%%#+*%%#####**##*****#%#==*%%%%%%%%%%%%%%%%%%%%#**++**#***#####
    +*+==++=+++#*+===*#%%%%%%%%%%%%%%%%%%%%%*+*%%#####*##*****#%#==#%%%%%%%%%%%%%%%%%%%%##******#*+**##*
    +**+=++=***#**++=+#%%%%%%%%%%%%%%%%%%%%%#++#%########*****#%*==#%%%%%%%%%%%%%%%%%%%%%##***+**#*+++**
    =+++++==+++*#+++++%%%%%%%%%%%%%%%%%%%%%%%*+*%#########****#%+=+%%%%%%%%%%%%%%%%%%%%%%###**#****#*++*
    =-=++++=++*+*+++**%%%%%%%%%%%%%%%%%%%%%%%#++#%#########***%#==*%%%%%%%%%%%%%%%%%%%%%%%#*#%###***##*+
    --=====+**+++++++*%%%%%%%%%%%%%%%%%%%%%%%%*+*%##########*#%*==#%%%%%%%%%%%%%%%%%%%%%%%##%%##*****##*
    -==++++**++++++++*%%%%%%%%%%%%%%%%%%%%%%%%#++%%#########*#%+==#%%%%%%%%%%%%%%%%%%%%%%%%%%%%##*******
    ++++++++===++++++#%%%%%%%%%%%%%%%%%%%%%%%%#++*%#########*#%+=+%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##**++*+
    +++++++=====+++++#%%%%%%%%%%%%%%%%%%%%%%%%%*++#%#########%#+=*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##**++*+
    ++*++++++===++++*#%%%%%%%%%%%%%%%%%%%%%%%%%#++*%#########%*+=*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##******
    +++*+++***+++++**%%%%%%%%%%%%%%%%%%%%%%%%%%%+++#%########%*++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##******
    **++*++**++++++*#%%%%%%%%%%%%%%%%%%%%%%%%%%%*++*%%%######%*++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####*##*
    =+****++++*+****#%%%%%%%%%%%%%%%%%%%%%%%%%%%#+=+%%%%%%###%+++%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%###*##*
    ==*###*++=*+***#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+#%%%%%%#%%++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#*******
    +==*###***#++**#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%%%%%%%#++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#**++++
    ++=+****=*#**##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=*%%%%%%%##++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#****
    ++++++***###%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%%%%%%+++%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@####
    ==+++*****##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+#%%%%%#++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####
    ++++***#####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%%%%#++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%######
    +*****####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+==#%%%%*++#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%#####
    +**+**###%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%%%*++%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#######
    ++***######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%#%%+++%%%%%%%%%%%%%%%%%%%%%%%%%%%%#%%%%%#######
    +****#####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*==#%%%++*%%%%%%%%%%%%%%%%%%%%%%%%%%#**#%%%########
    +********##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+=*%%#+=*%%%%%%%%%%%%%%%%%%%%%%%%#*++*##%%##%#####
    ++++*#****#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%#+=*%%%%%%%%%%%%%%%%%%%%%%%***++#%#%%########
    ++++*%#***#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+###+=*%%%%%%%%%%%%%%%%%%%%%#*+*#++%%%%%%#######
    ++++*%#***##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*=+###+=+%%%%%%%%%%%%%%%%%#*+**+++++#%#%%%########
    +++*******##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*==###+=+%%%%%%%%%%%%%%%%*++**+++++**#%%%%########
    +++*****#####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*==#%#+++%%%%%%%%%%%%%%%#***++*+*###%%%%%%########
    +++*****####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==#%%+++%%%%%%%%%%%%%%%%%*++*+=+##%%%%%%%########
    *+++*+****####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%++=#%%%%%%%%%%%%%%%%+++++=+*%%%%%%%%*%######
    #+++++****+++**##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%*+=#%%%%%%%%%%%%%%%*+=++++*#%%%%%%%#=#######
    @*+++++*++++*++*****#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#+=*%%*+=#%%%%%%%%%%%%###+++*+**#%%#%%%%%#:*######
    @*++++*++++++++***++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%*+=#%%%%%%%%%%%###*+=*+*%%%%##%%%%%#:*######
    @#+++*++++**+++***++*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%#+=*%%%%%%%%%%%##%*+=*+*#%%#%#%%#%%#:+######
    @@*+**+++***#*****+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%#++*%%%%%%%%%%%%%%+=+***#*%%#%%##%%*:=#%####
    @@*+*+++++**#######%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*=+%%%++*%%%%%%%%%%%%%*+=**%**#%%%%###%%*:-######
    @@#+*++++++**##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*==#%%+++%%%%%%%%%%%%#**+*#*+#%%%%###%%%*:=######
    @@#***++++++**#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*==#%%+++%%%%%%%%%%%%%#*++++*%%%%##%#*%%*:=######
    @@%*#*++++++++*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==#%%+++%%%%%%%%%%%%%%%#**+#%%%%##%*#%%*-*######
    @@@*##*++++++++*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==#%%*++%%%%%%%%%%%%%%%%%*+#%%%%%%#*%%%*+#######
    @@@####*+++++++**#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%*++#%%%%%%%%%%%%%%%%**%%%%%%**%%%%#########
    @@@%####*++++++***##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=*%%*+=#%%%%%%%%%%%%%%%%#*%%%%*+*%%%%%#########
    @@@@%####+++++******##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=*%%*+=#%%%%%%%%%%%%%%%%%#%#***#%%%%%###***####
    @@@@@@%###*++++********#%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=*%%*+=#%%%%%%%%%%%%%%%%##**+*%%%%%%%##*****###
    @@@@@@@@@@%*++++*++***+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%#+=#%%%%%%%%%%%%%%%%***##%%%%%%%%##*****###
    @@@@@@@@@@@%++++******++#%%%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%#+=#%%%%%%%%%%%%%##*+*%%%%%%%%%%###*#***###
    @@@@@@@@@@@@@*+++**********#%%%%%%%%%%%%%%%%%%%%%%%%*=+%%#+=*%%%%%%%%%%%%*++*%%%%%%%%%%%%#####***###
    @@@@@@@@@@@@@@#+++**+*****+*%%%%%%%%%%%%%%%%%%%%%%%%*=+%%%+=*%%%%%%%%%%##**%%%%%%%%%%%%%%#####***###
    @@@@@@@@@@@@@@@#+++++++**+++*%%%%%%%%%%%%%%%%%%%%%%%*==#%%++*%%%%%%%%%%###%%%%%%%%%%%%%%#####+**####
    @@@@@@@@@@@@@@@@%*++++****++*%%%%%%%%%%%%%%%%%%%%%%%#==#%%++*%%%%%%%%%%%%%%%%%%%%%%%%%%#####*+#*###*
    @@@@@@@@@@@@@@@@@@@%*++++++*%%%%%%%%%%%%%%%%%%%%%%%%#==#%%*++%%%%%%%%%%%%%%%%%%%%%%%%%*+*##*-**#####
    @@@@@@@@@@@@@@@@@@@@@#######%%%%%%%%%%%%%%%%%%%%%%%%#==#%%*++%%%%%%%%%%%%%%%%%%%%%%%%#*+****=**#####
    @@@@@@@@@@@@@@@@@@@@@%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#==*%%*++%%%%%%%%%%%%%%%%%%%%%%%*#@%##%@***#####
    @@@@@@@@@@@@@@@@@@@@@@@%#%%%%%%%%%%%%%%%%%%%%%%%%%%%%+=*%%*++%%%%%%%%%%%%%%%%%%%%%%*+%@@@@@@***#*###
    @@@@@@@@@@@@@@@@@@@@@@@@%#%%%%%%%%%%%%%%%%%%%%%%%%%%%+=*%%*++#%%%%%%%%%%%%%%%%%%%%*++%@@@@@#**##****
    @@@@@@@@@@@@@@@@@@@@@@@@@**#%%%%%%%%%%%%%%%%%%%%%%%%%+=+%%#+=#%%%%%%%%%%%%%%%%%%#*+++%@@@@@**##*****
    @@@@@@@@@@@@@@@@@@@@@@@@@*++*#%%%%%%%%%%%%%%%%%%%%%%%*=+%%#+=*%%%%%%%%%%%%%%%%#*++*++%@@@@#****+**#*
    @@@@@@@@@@@@@@@@@@@@@@@@@#++++*##%%%%%%%%%%%%%%%%%%%%+==#%#+=*%%%%%%%%%%%%%%%#****+++@@@@%****+**#**
    @@@@@@@@@@@@@@@@@@@@@@@@@#++++++**####%%%%%%%%%%%%%%%*==#%#+=*%%%%%%%%%%%%%#******+++@@@%***++******
    @@@@@@@@@@@@@@@@@@@@@@@@@#+++++++++**++*#%%%%#*#***#%#==*%#+=+%%%%%%%%%%%#*********++%@@%+*+=****+**
    @@@@@@@@@@@@@@@@@@@@@@@@@%+++++++++***+==+++++***#*+**==+##==+%%%%%%%%%%*+*********++@@@@%*+****+***
    @@@@@@@@@@@@@@@@@@@@@@@@@%++++++++++***++==++****###+====+**+++%@%%%%%#*+*********+++@@@@@#+*******%
    @@@@@@@@@@@@@@@@@@@@@@@@@@++++++++++*************#+*%*=*%+***++*@@@@%#++***********+*@@@@@%*##+**%@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@*++++++++++************#*+%#=*@****+++*%@@#++************+*@@@@@@@@@%%@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@#+++++++++++*************+%#+*@#****++++**++************++*@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@%++++++++++++************+%#+*@%*****++++++**+**********++#@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@%++++++++++++************+%%+*@%******++++**+***********++#@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@++++++++++++++**********+%%+*@@********++++++**********++%@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@*++++++++++++++**********#%+*@@*******+++++++**********++@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@#++++++++++++++*******#*+#%++@@#+***+++++++++**********+*@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@%++++++++++++++++*****#*+*%++@@@+***++++++*************+*@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@++++++++++++++++*******+*%++@@@+***++++++++***********+#@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@*++++++++++++++++******+#%+*@@%+****+*+++*+***********+%@@@@@@@@@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@%+++++++++++++++++*****+#%+#@@%+*******++*************+@@@@@@@@@@@@@@@@@
    """
    
    // MARK: - String.fileExtensionGroup(from:)
    func testFileExtensionGroupCreateFrom_withImageExtensions() throws {
        Self.imageExtensions.forEach {
            let group = String.makeFileExtensionGroup(from: $0)
            XCTAssertTrue(group.isImage)
            XCTAssertTrue(group.isVisualMedia)
            XCTAssertTrue(group.isKnown)
            
            XCTAssertFalse(group.isVideo)
            XCTAssertFalse(group.isAudio)
            XCTAssertFalse(group.isMultiMedia)
            XCTAssertFalse(group.isText)
            XCTAssertFalse(group.isWebCode)
            XCTAssertFalse(group.isEditableText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withVideoExtensions() throws {
        Self.videoExtensions.forEach {
            let group = String.makeFileExtensionGroup(from: $0)
            XCTAssertTrue(group.isVideo)
            XCTAssertTrue(group.isVisualMedia)
            XCTAssertTrue(group.isMultiMedia)
            XCTAssertTrue(group.isKnown)
            
            XCTAssertFalse(group.isAudio)
            XCTAssertFalse(group.isText)
            XCTAssertFalse(group.isWebCode)
            XCTAssertFalse(group.isEditableText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withAudioExtensions() throws {
        Self.audioExtensions.forEach {
            let group = String.makeFileExtensionGroup(from: $0)
            XCTAssertTrue(group.isAudio)
            XCTAssertTrue(group.isMultiMedia)
            XCTAssertTrue(group.isKnown)
            
            XCTAssertFalse(group.isImage)
            XCTAssertFalse(group.isVideo)
            XCTAssertFalse(group.isVisualMedia)
            XCTAssertFalse(group.isText)
            XCTAssertFalse(group.isWebCode)
            XCTAssertFalse(group.isEditableText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withTextPathExtension() throws {
        Self.textPathExtension.forEach {
            let group = String.makeFileExtensionGroup(from: $0)
            XCTAssertTrue(group.isText)
            XCTAssertTrue(group.isEditableText)
            XCTAssertTrue(group.isKnown)
            
            XCTAssertFalse(group.isImage)
            XCTAssertFalse(group.isVideo)
            XCTAssertFalse(group.isAudio)
            XCTAssertFalse(group.isVisualMedia)
            XCTAssertFalse(group.isMultiMedia)
            XCTAssertFalse(group.isWebCode)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withWebCodePathExtension() throws {
        Self.webCodePathExtension.forEach {
            let group = String.makeFileExtensionGroup(from: $0)
            XCTAssertTrue(group.isWebCode)
            XCTAssertTrue(group.isEditableText)
            XCTAssertTrue(group.isKnown)
            
            XCTAssertFalse(group.isImage)
            XCTAssertFalse(group.isVideo)
            XCTAssertFalse(group.isAudio)
            XCTAssertFalse(group.isVisualMedia)
            XCTAssertFalse(group.isMultiMedia)
            XCTAssertFalse(group.isText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withEmptyString() throws {
        let group = String.makeFileExtensionGroup(from: "")
        XCTAssertTrue(group.isEditableText)
        XCTAssertTrue(group.isKnown)
        
        XCTAssertFalse(group.isImage)
        XCTAssertFalse(group.isVideo)
        XCTAssertFalse(group.isAudio)
        XCTAssertFalse(group.isVisualMedia)
        XCTAssertFalse(group.isMultiMedia)
        XCTAssertFalse(group.isText)
        XCTAssertFalse(group.isWebCode)
    }
    
    func testFileExtensionGroupCreateFrom_withNumericString() throws {
        let group = String.makeFileExtensionGroup(from: "-0123456789")
        XCTAssertFalse(group.isKnown)
        XCTAssertFalse(group.isImage)
        XCTAssertFalse(group.isVideo)
        XCTAssertFalse(group.isAudio)
        XCTAssertFalse(group.isVisualMedia)
        XCTAssertFalse(group.isMultiMedia)
        XCTAssertFalse(group.isText)
        XCTAssertFalse(group.isWebCode)
        XCTAssertFalse(group.isEditableText)
    }
    
    func testFileExtensionGroupCreateFrom_withEmoji() throws {
        let emojisAndEmoticons = ["😀", "¯\\_(ツ)_/¯"]
        emojisAndEmoticons.forEach {
            let group = String.makeFileExtensionGroup(from: $0)
            XCTAssertFalse(group.isKnown)
            XCTAssertFalse(group.isImage)
            XCTAssertFalse(group.isVideo)
            XCTAssertFalse(group.isAudio)
            XCTAssertFalse(group.isVisualMedia)
            XCTAssertFalse(group.isMultiMedia)
            XCTAssertFalse(group.isText)
            XCTAssertFalse(group.isWebCode)
            XCTAssertFalse(group.isEditableText)
        }
        
    }
    
    func testFileExtensionGroupCreateFrom_withVeryLongString() throws {
        let group = String.makeFileExtensionGroup(from: Self.maloneyBologna)
        XCTAssertFalse(group.isKnown)
        XCTAssertFalse(group.isImage)
        XCTAssertFalse(group.isVideo)
        XCTAssertFalse(group.isAudio)
        XCTAssertFalse(group.isVisualMedia)
        XCTAssertFalse(group.isMultiMedia)
        XCTAssertFalse(group.isText)
        XCTAssertFalse(group.isWebCode)
        XCTAssertFalse(group.isEditableText)
    }
    
    // MARK: - String.fileExtensionGroup(verify:_:)
    func testFileExtensionGroupVerify_withImageExtensions() throws {
        Self.imageExtensions.forEach {
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isImage))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isVisualMedia))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isKnown))
            
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVideo))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isAudio))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isMultiMedia))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isWebCode))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isEditableText))
        }
    }
    
    func testFileExtensionGroupVerify_withVideoExtensions() throws {
        Self.videoExtensions.forEach {
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isVideo))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isVisualMedia))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isMultiMedia))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isKnown))
            
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isImage))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isAudio))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isWebCode))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isEditableText))
        }
    }
    
    func testFileExtensionGroupVerify_withAudioExtensions() throws {
        Self.audioExtensions.forEach {
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isAudio))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isMultiMedia))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isKnown))
            
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isImage))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVideo))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isWebCode))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isEditableText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVisualMedia))
        }
    }
    
    func testFileExtensionGroupVerify_withTextPathExtension() throws {
        Self.textPathExtension.forEach {
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isText))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isEditableText))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isKnown))
            
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isImage))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVideo))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isAudio))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isWebCode))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVisualMedia))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isMultiMedia))
        }
    }
    
    func testFileExtensionGroupVerify_withWebCodePathExtension() throws {
        Self.webCodePathExtension.forEach {
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isWebCode))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isEditableText))
            XCTAssertTrue(String.fileExtensionGroup(verify: $0, \.isKnown))
            
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isImage))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVideo))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isAudio))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVisualMedia))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isMultiMedia))
        }
    }
    
    func testFileExtensionGroupVerify_withEmptyString() throws {
        let str = ""
        XCTAssertTrue(String.fileExtensionGroup(verify: str, \.isEditableText))
        XCTAssertTrue(String.fileExtensionGroup(verify: str, \.isKnown))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isImage))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isVideo))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isAudio))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isText))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isWebCode))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isVisualMedia))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isMultiMedia))
    }
    
    func testFileExtensionGroupVerify_withNumericString() throws {
        let str = "-0123456789"
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isImage))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isVideo))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isAudio))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isText))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isWebCode))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isEditableText))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isVisualMedia))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isMultiMedia))
        XCTAssertFalse(String.fileExtensionGroup(verify: str, \.isKnown))
    }
    
    func testFileExtensionGroupVerify_withEmoji() throws {
        let emojisAndEmoticons = ["😀", "¯\\_(ツ)_/¯"]
        emojisAndEmoticons.forEach {
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isImage))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVideo))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isAudio))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isWebCode))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isEditableText))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isVisualMedia))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isMultiMedia))
            XCTAssertFalse(String.fileExtensionGroup(verify: $0, \.isKnown))
        }
        
    }
    
    func testFileExtensionGroupVerify_withVeryLongString() throws {
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isImage))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isVideo))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isAudio))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isText))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isWebCode))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isEditableText))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isVisualMedia))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isMultiMedia))
        XCTAssertFalse(String.fileExtensionGroup(verify: Self.maloneyBologna, \.isKnown))
    }
}
