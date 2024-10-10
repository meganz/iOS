@testable import MEGASwift
import XCTest

final class StringFileExtensionGroupTests: XCTestCase {
    private static let emptyExtension = ""
    private static let imageExtensions = ["3fr", "arw", "bmp", "cr2", "crw", "ciff", "cur", "cs1", "dcr", "dng", "erf", "gif", "heic", "ico", "iiq", "j2c", "jp2", "jpf", "jpeg", "jpg", "k25", "kdc", "mef", "mos", "mrw", "nef", "nrw", "orf", "pbm", "pef", "pgm", "png", "pnm", "ppm", "psd", "raf", "raw", "rw2", "rwl", "sr2", "srf", "srw", "tga", "tif", "tiff", "webp", "x3f"]
    private static let videoExtensions = ["3g2", "3gp", "avi", "mkv", "m4v", "mov", "mp4", "mqv", "qt"]
    private static let audioExtensions = ["aac", "ac3", "aif", "aiff", "au", "caf", "eac3", "ec3", "flac", "m4a", "mp3", "wav"]
    private static let textPathExtension = ["txt", "ans", "ascii", "log", "wpd", "json", "md", "org"]
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
    
    func testFileExtensionGroupCreateFrom_withImageExtensions() throws {
        Self.imageExtensions.forEach {
            XCTAssertTrue($0.fileExtensionGroup.isImage)
            XCTAssertTrue($0.fileExtensionGroup.isVisualMedia)
            XCTAssertTrue($0.fileExtensionGroup.isKnown)
            
            XCTAssertFalse($0.fileExtensionGroup.isVideo)
            XCTAssertFalse($0.fileExtensionGroup.isAudio)
            XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
            XCTAssertFalse($0.fileExtensionGroup.isText)
            XCTAssertFalse($0.fileExtensionGroup.isWebCode)
            XCTAssertFalse($0.fileExtensionGroup.isEditableText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withImageFileNames() throws {
        Self.imageExtensions
            .map { "FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isImage)
                XCTAssertTrue($0.fileExtensionGroup.isVisualMedia)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
                XCTAssertFalse($0.fileExtensionGroup.isText)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
                XCTAssertFalse($0.fileExtensionGroup.isEditableText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withImageFilePaths() throws {
        Self.imageExtensions
            .map { "/XCImageset.xcasset/FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isImage)
                XCTAssertTrue($0.fileExtensionGroup.isVisualMedia)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
                XCTAssertFalse($0.fileExtensionGroup.isText)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
                XCTAssertFalse($0.fileExtensionGroup.isEditableText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withVideoExtensions() throws {
        Self.videoExtensions.forEach {
            XCTAssertTrue($0.fileExtensionGroup.isVideo)
            XCTAssertTrue($0.fileExtensionGroup.isVisualMedia)
            XCTAssertTrue($0.fileExtensionGroup.isMultiMedia)
            XCTAssertTrue($0.fileExtensionGroup.isKnown)
            
            XCTAssertFalse($0.fileExtensionGroup.isAudio)
            XCTAssertFalse($0.fileExtensionGroup.isText)
            XCTAssertFalse($0.fileExtensionGroup.isWebCode)
            XCTAssertFalse($0.fileExtensionGroup.isEditableText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withVideoFileNames() throws {
        Self.videoExtensions
            .map { "FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isVideo)
                XCTAssertTrue($0.fileExtensionGroup.isVisualMedia)
                XCTAssertTrue($0.fileExtensionGroup.isMultiMedia)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isText)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
                XCTAssertFalse($0.fileExtensionGroup.isEditableText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withVideoFilePaths() throws {
        Self.videoExtensions
            .map { "/XCImageset.xcasset/FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isVideo)
                XCTAssertTrue($0.fileExtensionGroup.isVisualMedia)
                XCTAssertTrue($0.fileExtensionGroup.isMultiMedia)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isText)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
                XCTAssertFalse($0.fileExtensionGroup.isEditableText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withAudioExtensions() throws {
        Self.audioExtensions.forEach {
            XCTAssertTrue($0.fileExtensionGroup.isAudio)
            XCTAssertTrue($0.fileExtensionGroup.isMultiMedia)
            XCTAssertTrue($0.fileExtensionGroup.isKnown)
            
            XCTAssertFalse($0.fileExtensionGroup.isImage)
            XCTAssertFalse($0.fileExtensionGroup.isVideo)
            XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
            XCTAssertFalse($0.fileExtensionGroup.isText)
            XCTAssertFalse($0.fileExtensionGroup.isWebCode)
            XCTAssertFalse($0.fileExtensionGroup.isEditableText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withAudioFileNames() throws {
        Self.audioExtensions
            .map { "FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isAudio)
                XCTAssertTrue($0.fileExtensionGroup.isMultiMedia)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isImage)
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
                XCTAssertFalse($0.fileExtensionGroup.isText)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
                XCTAssertFalse($0.fileExtensionGroup.isEditableText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withAudioFilePaths() throws {
        Self.audioExtensions
            .map { "/XCImageset.xcasset/FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isAudio)
                XCTAssertTrue($0.fileExtensionGroup.isMultiMedia)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isImage)
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
                XCTAssertFalse($0.fileExtensionGroup.isText)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
                XCTAssertFalse($0.fileExtensionGroup.isEditableText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withTextPathExtension() throws {
        Self.textPathExtension.forEach {
            XCTAssertTrue($0.fileExtensionGroup.isText)
            XCTAssertTrue($0.fileExtensionGroup.isEditableText)
            XCTAssertTrue($0.fileExtensionGroup.isKnown)
            
            XCTAssertFalse($0.fileExtensionGroup.isImage)
            XCTAssertFalse($0.fileExtensionGroup.isVideo)
            XCTAssertFalse($0.fileExtensionGroup.isAudio)
            XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
            XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
            XCTAssertFalse($0.fileExtensionGroup.isWebCode)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withTextFileNames() throws {
        Self.textPathExtension
            .map { "FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isText)
                XCTAssertTrue($0.fileExtensionGroup.isEditableText)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isImage)
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
                XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withTextFilePaths() throws {
        Self.textPathExtension
            .map { "/XCImageset.xcasset/FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isText)
                XCTAssertTrue($0.fileExtensionGroup.isEditableText)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isImage)
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
                XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
                XCTAssertFalse($0.fileExtensionGroup.isWebCode)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withWebCodePathExtension() throws {
        Self.webCodePathExtension.forEach {
            XCTAssertTrue($0.fileExtensionGroup.isWebCode)
            XCTAssertTrue($0.fileExtensionGroup.isEditableText)
            XCTAssertTrue($0.fileExtensionGroup.isKnown)
            
            XCTAssertFalse($0.fileExtensionGroup.isImage)
            XCTAssertFalse($0.fileExtensionGroup.isVideo)
            XCTAssertFalse($0.fileExtensionGroup.isAudio)
            XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
            XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
            XCTAssertFalse($0.fileExtensionGroup.isText)
        }
    }
    
    func testFileExtensionGroupCreateFrom_withWebCodeFileName() throws {
        Self.webCodePathExtension
            .map { "FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isWebCode)
                XCTAssertTrue($0.fileExtensionGroup.isEditableText)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isImage)
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
                XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
                XCTAssertFalse($0.fileExtensionGroup.isText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withWebCodeFilePath() throws {
        Self.webCodePathExtension
            .map { "/XCImageset.xcasset/FileName.\($0)" }
            .forEach {
                XCTAssertTrue($0.fileExtensionGroup.isWebCode)
                XCTAssertTrue($0.fileExtensionGroup.isEditableText)
                XCTAssertTrue($0.fileExtensionGroup.isKnown)
                
                XCTAssertFalse($0.fileExtensionGroup.isImage)
                XCTAssertFalse($0.fileExtensionGroup.isVideo)
                XCTAssertFalse($0.fileExtensionGroup.isAudio)
                XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
                XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
                XCTAssertFalse($0.fileExtensionGroup.isText)
            }
    }
    
    func testFileExtensionGroupCreateFrom_withEmptyString() throws {
        let str = ""
        XCTAssertTrue(str.fileExtensionGroup.isEditableText)
        XCTAssertTrue(str.fileExtensionGroup.isKnown)
        
        XCTAssertFalse(str.fileExtensionGroup.isImage)
        XCTAssertFalse(str.fileExtensionGroup.isVideo)
        XCTAssertFalse(str.fileExtensionGroup.isAudio)
        XCTAssertFalse(str.fileExtensionGroup.isVisualMedia)
        XCTAssertFalse(str.fileExtensionGroup.isMultiMedia)
        XCTAssertFalse(str.fileExtensionGroup.isText)
        XCTAssertFalse(str.fileExtensionGroup.isWebCode)
    }
    
    func testFileExtensionGroupCreateFrom_withNumericString() throws {
        let str = "-0123456789"
        XCTAssertFalse(str.fileExtensionGroup.isKnown)
        XCTAssertFalse(str.fileExtensionGroup.isImage)
        XCTAssertFalse(str.fileExtensionGroup.isVideo)
        XCTAssertFalse(str.fileExtensionGroup.isAudio)
        XCTAssertFalse(str.fileExtensionGroup.isVisualMedia)
        XCTAssertFalse(str.fileExtensionGroup.isMultiMedia)
        XCTAssertFalse(str.fileExtensionGroup.isText)
        XCTAssertFalse(str.fileExtensionGroup.isWebCode)
        XCTAssertFalse(str.fileExtensionGroup.isEditableText)
    }
    
    func testFileExtensionGroupCreateFrom_withEmoji() throws {
        let emojisAndEmoticons = ["😀", "¯\\_(ツ)_/¯"]
        emojisAndEmoticons.forEach {
            XCTAssertFalse($0.fileExtensionGroup.isKnown)
            XCTAssertFalse($0.fileExtensionGroup.isImage)
            XCTAssertFalse($0.fileExtensionGroup.isVideo)
            XCTAssertFalse($0.fileExtensionGroup.isAudio)
            XCTAssertFalse($0.fileExtensionGroup.isVisualMedia)
            XCTAssertFalse($0.fileExtensionGroup.isMultiMedia)
            XCTAssertFalse($0.fileExtensionGroup.isText)
            XCTAssertFalse($0.fileExtensionGroup.isWebCode)
            XCTAssertFalse($0.fileExtensionGroup.isEditableText)
        }
        
    }
    
    func testFileExtensionGroupCreateFrom_withVeryLongString() throws {
        let str = Self.maloneyBologna
        XCTAssertFalse(str.fileExtensionGroup.isKnown)
        XCTAssertFalse(str.fileExtensionGroup.isImage)
        XCTAssertFalse(str.fileExtensionGroup.isVideo)
        XCTAssertFalse(str.fileExtensionGroup.isAudio)
        XCTAssertFalse(str.fileExtensionGroup.isVisualMedia)
        XCTAssertFalse(str.fileExtensionGroup.isMultiMedia)
        XCTAssertFalse(str.fileExtensionGroup.isText)
        XCTAssertFalse(str.fileExtensionGroup.isWebCode)
        XCTAssertFalse(str.fileExtensionGroup.isEditableText)
    }
}
