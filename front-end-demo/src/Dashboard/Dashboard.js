import React from 'react';
import {Button, Select} from 'antd';
import 'antd/dist/antd.css';
import './Dashboard.css';
import { ToolOutlined, UploadOutlined, RotateRightOutlined, SaveOutlined, HomeOutlined} from '@ant-design/icons'

const Option = Select.Option;

const children = [];

children.push(<Option key="1">COMPILER:GCC8.0</Option>);
children.push(<Option key="2">COMPILER:GCC7.0</Option>);
children.push(<Option key="3">COMPILER:GCC6.0</Option>);
children.push(<Option key="4">COMPILER:GCC5.0</Option>);
children.push(<Option key="5">RUNTIME:LLVM</Option>);
children.push(<Option key="6">RUNTIME:GOMP</Option>);
children.push(<Option key="7">LIB:MPI</Option>);
children.push(<Option key="8">LIB:MKL</Option>);

class Dashboard extends React.Component {
    state = {
        myDisplay: 'row',
        myWidth: 0
    };
    
    constructor(props) {
        super(props);
        this.resize.bind(this);
    };

    componentDidMount() {
        this.screenChange();

        if (document.body.clientWidth <= 700) {
            this.setState({myDisplay: 'column'});
        } else {
            this.setState({myDisplay: 'row'});
        }
    };

    componentWillUnmount() {
        window.removeEventListener('resize',this.resize);
    };
    
    resize  = () => {
        this.setState({myWidth: document.body.clientWidth});
        console.log(this.state.myWidth);
        if (this.state.myWidth <= 700) {
            this.setState({myDisplay: 'column'});
        } else {
            this.setState({myDisplay: 'row'});
        }
    };

    screenChange = () => {
        window.addEventListener('resize', this.resize);
    }
              
    Onclk = () => {
       if (this.state.myDisplay == 'row') {
           this.setState({myDisplay: 'column'});
       } else {
           this.setState({myDisplay: 'row'});
       }

       console.log('display changed!');
    };
              
    render() {
        return (
            <div>
                <div className = "logo">
                    <b><ToolOutlined /> | onlineCompiler</b>
                </div>
                <div className = "opts">
                    <Button><HomeOutlined /></Button>
                    <Button><UploadOutlined /></Button>
                    <Button><SaveOutlined /></Button>
                    <Button onClick = {() => this.Onclk()} ><RotateRightOutlined /></Button>
                    <Button type="primary">Compile</Button>
                </div>
                <div className = "tags">
                    <Select
                      mode="multiple"
                      style={{ width: '100%' }}
                      placeholder="Please select compile configurations"
                      defaultValue={['1', '5']}
                    >
                      {children}
                    </Select>
                </div>
                <div className = "texts" style = {{flexDirection: this.state.myDisplay}}>
                    <textarea className = "inputbox" placeholder="Type or upload your code"/>
                    <textarea className = "outputbox" placeholder="Results/Error messages will be shown here"/>
                </div>
            </div>
        )
    };
}

export default Dashboard;
