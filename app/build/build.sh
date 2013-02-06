# --- Define Vars ---
DC=ldc
DFLAGS="-nodefaultlib -code-model=large -I${ROOT} -I${ROOT}/app/d/include -I${ROOT}/runtimes -J${ROOT}/build/root -mattr=-sse -m64 -O0 -release -g"

# if not defined, provide defau;lt name for ROOT_FILE based on TARGET
if [ -z "${ROOT_FILE}" ]; then
		ROOT_FILE=${TARGET}.d
fi

# --- Build App ---
echo Preparing Filesystem
mkdir -p objs
rm objs/*.o

echo
echo Creating Application Executable
echo "--> ${TARGET}"

echo
echo "--> ${ROOT_FILE}"
${DC} ${ROOT_FILE} ${DFLAGS} -c -oq -odobjs

for item in `${DC} ${ROOT_FILE} -c -o- -oq -v ${DFLAGS} | sed 's/import\s*\(tango\|object\|ldc\)//' | grep "import " | sed 's/import\s*\S*\s*[(]\([^)]*\)[)]/\1/'`
do
        echo "--> ${item#$ROOT/}"
        ${DC} ${item} ${DFLAGS} -c -oq -odobjs
done

if [ -z "${DYNAMIC_RUNTIME}" ]; then
  x86_64-pc-xomb-ld -nostdlib -nodefaultlibs -T${ROOT}/app/build/elf.ld -o ${TARGET} `ls objs/*.o` ${ROOT}/runtimes/mindrt/drt0.a ${ROOT}/runtimes/mindrt/mindrt.a ${ROOT}/runtimes/mindrt/libd.a ${EXTRA_LIBS}
else
  echo "DYNAMIC"
  x86_64-pc-xomb-ld -nostdlib -nodefaultlibs -T${ROOT}/app/build/elf.ld -o ${TARGET} `ls objs/*.o` ${ROOT}/runtimes/mindrt/drt0.a ${ROOT}/runtimes/dyndrt/dyndrt.a ${ROOT}/runtimes/mindrt/libd.a ${EXTRA_LIBS}
fi

echo
echo Copying
strip -s ${TARGET} -o ${ROOT}/build/root/binaries/${TARGET}

echo
echo Creating App Symbol File
echo "--> ${TARGET}.sym"
${ROOT}/build/mkldsym.sh ${TARGET} ${TARGET}.sym
