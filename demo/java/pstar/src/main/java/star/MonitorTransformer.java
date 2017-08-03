package star;

import javassist.ClassPool;
import javassist.CtClass;
import net.sf.cglib.proxy.Enhancer;
import org.objectweb.asm.ClassWriter;

import java.beans.PropertyChangeSupport;
import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.IllegalClassFormatException;
import java.security.ProtectionDomain;

/**
 * @author Tietang Wang 铁汤
 * @Date: 2017/6/5 17:24
 * @blog http://tietang.wang
 */
public class MonitorTransformer implements ClassFileTransformer {

    @Override
    public byte[] transform(
            ClassLoader loader,
            String className,
            Class<?> classBeingRedefined,
            ProtectionDomain protectionDomain,
            byte[] classfileBuffer) throws IllegalClassFormatException {
        Enhancer e = new Enhancer();
        e.setSuperclass(classBeingRedefined);
//        e.setCallback(interceptor.c);
        Object bean = e.create();
      Class clazz=  e.createClass();

        return new byte[0];
    }
}
