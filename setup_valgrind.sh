# setup Valgrind
cd ~
svn co svn://svn.valgrind.org/valgrind/trunk valgrind

cd valgrind
./autogen.sh
./configure --prefix=/home/ilvin/local/
make
make install


# Setup KCachegrind (need desktop)
sudo apt-get install kcachegrind
