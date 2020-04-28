import React from 'react';
import './Login.css';
import {Button, Drawer, Table, message, Link} from 'antd';

class Dashboard extends React.Component {
    state = {};
    
    componentDidMount() {
        
    };
    
    runtime_cfg = () => {
        console.log("Runtime!");
    };
    
    render() {
        return (
            <div>
                <h1>this page is for users!</h1>
            </div>
        )
    };
}

export default Dashboard;
