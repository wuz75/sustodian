from setuptools import setup, find_packages

setup(
    name='sustodian',
    version='0.1.0',
    author='wuz75',
    author_email='author@example.com',
    description='A description of the sustodian project',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url='https://github.com/wuz75/sustodian',
    packages=find_packages(),
    install_requires=[
        # Add dependencies here, e.g.,
        # 'numpy',
        # 'pandas',
    ],
    classifiers=[
        'Programming Language :: Python :: 3',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
    ],
    python_requires='>=3.6',
)

